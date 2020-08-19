pipeline {
    agent any
    environment {
        KUBECONFIG = credentials('kube-config')
        REGISTRY_URI = '866421524471.dkr.ecr.us-east-2.amazonaws.com/hello-flask'
    }
    stages {
        stage('Linting App and Dockerfile') {
            steps {
                echo 'Linting Python code and Dockerfile'
                sh 'pylint --disable=C0114,C0116 *.py'
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
                        docker tag hello-flask:${BUILD_NUMBER} $REGISTRY_URI:${BUILD_NUMBER}
                        docker push $REGISTRY_URI:${BUILD_NUMBER}
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
                echo 'Performing Rolling Update'
                withAWS(region:'us-east-2',credentials:'aws-static') {
                    sh 'kubectl -n $BRANCH_NAME set image deployment/hello-flask hello-flask=$REGISTRY_URI:${BUILD_NUMBER} --record'
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
                    // script {
                    //     env.BLUE_NAME = sh(script: 'kubectl -n $BRANCH_NAME get svc -l role=blue -o json | jq -r \'.items[].metadata.name\'', returnStdout: true).trim()
                    //     echo "LS = ${env.BLUE_NAME}"
                    // }
                    sh '''
                        sed -i "s/build-0/build-$BUILD_NUMBER/g" nodegroup/parameters.json
                        aws cloudformation create-stack \
                            --capabilities CAPABILITY_IAM \
                            --stack-name CapstoneEKS-Workers-Build-${BUILD_NUMBER} \
                            --parameters file://nodegroup/parameters.json \
                            --template-body file://nodegroup/eks-nodegroup-bg.yaml \
                            --region us-east-2
                        kubectl -n $BRANCH_NAME get all -l role=blue
                        sleep 90

                        sed -i "s/GREEN/$BUILD_NUMBER/g"  kubernetes/deployment-green.yaml
                        kubectl -n $BRANCH_NAME apply -f  kubernetes/deployment-green.yaml

                        sed -i "s/GREEN/$BUILD_NUMBER/g"  kubernetes/service-green.yaml
                        kubectl -n $BRANCH_NAME apply -f  kubernetes/service-green.yaml

                        BLUE_NAME=$(kubectl -n $BRANCH_NAME get svc -l role=blue -o json | jq -r '.items[0].metadata.name')
                        sed -i "s/BLUE_NAME/$BLUE_NAME/g" kubernetes/ingress-bg.yaml
                        sed -i "s/GREEN/$BUILD_NUMBER/g"  kubernetes/ingress-bg.yaml
                        cat kubernetes/ingress-bg.yaml
                        kubectl -n $BRANCH_NAME apply -f  kubernetes/ingress-bg.yaml
                        kubectl -n $BRANCH_NAME get all -l role=green
                    '''
                }
            }
        }
        stage('Test Green Environment') {
            when {
                branch 'production'
            }
            steps {
                echo 'Testing Green Environment'
                withAWS(region:'us-east-2',credentials:'aws-static') {
                    sh '''
                    # sleep 90
                    echo 'Testing blue environment'
                    curl -v http://prod.devopsmaster.cloud
                    echo 'Testing green environment'
                    curl -v http://green.devopsmaster.cloud
                    '''
                }
            }
        }
        stage('Switch to Green Environment') {
            when {
                branch 'production'
            }
            steps {
                echo 'Switch to Green Environment'
                withAWS(region:'us-east-2',credentials:'aws-static') {
                    sh '''
                    GREEN_NAME=$(kubectl -n $BRANCH_NAME get svc -l role=green -o json | jq -r '.items[].metadata.name')
                    sed -i "s/hello-flask-0/hello-flask-$BUILD_NUMBER/g" kubernetes/ingress-blue.yaml
                    kubectl -n $BRANCH_NAME apply -f  kubernetes/ingress-blue.yaml
                    sleep 10
                    kubectl -n $BRANCH_NAME delete deploy -l role=blue
                    kubectl -n $BRANCH_NAME delete service -l role=blue
                    kubectl -n $BRANCH_NAME patch service $GREEN_NAME --type='json' -p='[{"op": "replace", "path": "/metadata/labels/role", "value": "blue"}]'
                    kubectl -n $BRANCH_NAME patch deploy $GREEN_NAME --type='json' -p='[{"op": "replace", "path": "/metadata/labels/role", "value": "blue"}]'
                    kubectl -n $BRANCH_NAME get all -l role=blue
                    BLUE_STACK=$(aws cloudformation describe-stacks | jq -r .Stacks[1].StackName)
                    aws cloudformation delete-stack --stack-name ${BLUE_STACK} --region us-east-2
                    '''
                }
            }
        }
    }
}
