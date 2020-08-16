pipeline {
    agent any
    environment {
        KUBECONFIG = credentials('kube-config')
    }
    stages {
        stage('Linting App and Dockerfile') {
            // when {
            //     branch 'development'
            // }
            steps {
                // echo 'Building Pet Clinic with Maven'
                // sh './mvnw package'
                echo 'Running hadolint'
                sh 'hadolint Dockerfile'
            }
        }
        stage('Build Docker') {
            // when {
            //     branch 'staging'
            // }
            steps {
                echo 'Building Pet Clinic Docker container after linting'
                sh 'docker build -t spring-petclinic:${BUILD_NUMBER} .'
            }
        }
        stage('Security Scan') {
            // when {
            //     branch 'staging'
            // }
            steps {
                echo 'Starting security scan for the Docker image'
                // aquaMicroscanner imageName: 'alpine:latest', notCompliesCmd: 'exit 1', onDisallowed: 'fail', outputFormat: 'html'
                sh 'trivy --exit-code 0 --no-progress spring-petclinic:${BUILD_NUMBER}'
            }
        }
        stage('Push to ECR') {
            // when {
            //     branch 'deployment'
            // }
            steps {
                echo 'Uploading container to ECR with AWS creds'
                withAWS(region:'us-east-2',credentials:'aws-static') {
                    sh '''
                        aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 866421524471.dkr.ecr.us-east-2.amazonaws.com
                        docker tag spring-petclinic:${BUILD_NUMBER} 866421524471.dkr.ecr.us-east-2.amazonaws.com/spring-petclinic:${BUILD_NUMBER}
                        docker push 866421524471.dkr.ecr.us-east-2.amazonaws.com/spring-petclinic:${BUILD_NUMBER}
                    '''
                }
            }
        }
        stage('Deploy Green Environment') {
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
                    sh 'kubectl create deployment spring-petclinic-${BUILD_NUMBER} --image=866421524471.dkr.ecr.us-east-2.amazonaws.com/spring-petclinic:${BUILD_NUMBER}'
                    // upgrate ingress to prepare the green rule-set
                }
            }
        }
        stage('Test Green Environment') {
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
            steps {
                // change ingress
                echo 'Switch to Green Environment'
                withAWS(region:'us-east-2',credentials:'aws-static') {
                    sh 'kubectl get no'
                }
            }
        }
        stage('Remove Blue Environment') {
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
