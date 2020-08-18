pipeline {
    agent any
    environment {
        KUBECONFIG = credentials('kube-config')
    }
    stages {
        stage('Linting App and Dockerfile') {
            steps {
                echo 'Linting Python code and Dockerfile'
                sh 'pylint *.py'
                echo 'Running hadolint'
                sh 'hadolint Dockerfile'
            }
        }
        stage('Docker Build and Push to ECR') {
            steps {
                echo 'Uploading container to ECR with AWS creds'
                withAWS(region:'us-east-2',credentials:'aws-static') {
                    sh '''
                        echo 'Building Docker container'
                        docker build -t hello-flask:${BUILD_NUMBER} .
                        aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 866421524471.dkr.ecr.us-east-2.amazonaws.com
                        docker tag hello-flask:${BUILD_NUMBER} 866421524471.dkr.ecr.us-east-2.amazonaws.com/hello-flask:${BUILD_NUMBER}
                        docker push 866421524471.dkr.ecr.us-east-2.amazonaws.com/hello-flask:${BUILD_NUMBER}
                    '''
                }
            }
        }
        stage('Security Scan') {
            steps {
                echo 'Starting security scan for the Docker image'
                // aquaMicroscanner imageName: 'alpine:latest', notCompliesCmd: 'exit 1', onDisallowed: 'fail', outputFormat: 'html'
                sh 'trivy --exit-code 0 --no-progress hello-flask:${BUILD_NUMBER}'
            }
        }
        stage('Deploy to Development') {
            when {
                branch 'development'
            }
            steps {
                echo 'Deploying to development namespace'
                sh 'env'
                sh 'sed -i "s/TAG/$BUILD_NUMBER/g" kubernetes/deployment.yaml'
                withAWS(region:'us-east-2',credentials:'aws-static') {
                    sh 'kubectl apply -f kubernetes/*'
                }
            }
        }
        stage('Deploy Green Environment') {
            when {
                branch 'production'
            }
            steps {
                echo 'Launching the EKS stack...'
                withAWS(region:'us-east-2',credentials:'aws-static') {
                    sh '''
                        sed -i "s/BUILD/build-$BUILD_NUMBER/g" cloudformation/parameters.json
                        aws cloudformation create-stack \
                            --capabilities CAPABILITY_IAM \
                            --stack-name CapstoneEKS-Workers-Build-${BUILD_NUMBER} \
                            --parameters file://cloudformation/parameters.json \
                            --template-body file://cloudformation/eks-nodegroup-bg.yaml \
                            --region us-east-2
                    '''
                    sleep(120) {
                        // on interrupt do
                    }
                    sh 'kubectl create deployment hello-flask-${BUILD_NUMBER} --image=866421524471.dkr.ecr.us-east-2.amazonaws.com/hello-flask:${BUILD_NUMBER}'
                    // upgrate ingress to prepare the green rule-set
                }
            }
        }
        stage('Test Green Environment') {
            when {
                branch 'production'
            }
            steps {
                echo 'Testing Green Environment'
                // curl blue ingress
                // curl green ingress
                withAWS(region:'us-east-2',credentials:'aws-static') {
                    sh 'kubectl get po'
                }
            }
        }
        stage('Switch to Green Environment') {
            when {
                branch 'production'
            }
            steps {
                // change ingress
                echo 'Switch to Green Environment'
                withAWS(region:'us-east-2',credentials:'aws-static') {
                    sh 'kubectl get no'
                }
            }
        }
        stage('Remove Blue Environment') {
            when {
                branch 'production'
            }
            steps {
                echo 'Remove Blue Environment Stack'
                withAWS(region:'us-east-2',credentials:'aws-static') {
                    // delete kubernetes blue deployment
                    // change role labels from green to blue
                    script {
                        env.BLUE = sh(script: 'aws cloudformation describe-stacks | jq -r .Stacks[1].StackName', returnStdout: true).trim()
                        echo "LS = ${env.BLUE}"
                    }
                    sh '''
                        aws cloudformation delete-stack \
                          --stack-name ${BLUE} --region us-east-2
                    '''
                }
            }
        }
    }
}
