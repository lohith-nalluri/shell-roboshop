#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIRE=$PWD
MONGODB_HOST=mongodb-dev.crazycoolmaster.space


if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y  &>> $LOGS_FILE
VALIDATE $? "Disabling NodeJS module"

dnf module enable nodejs:20 -y  &>> $LOGS_FILE
VALIDATE $? "Enabling NodeJS module"

dnf install nodejs -y  &>> $LOGS_FILE
VALIDATE $? "Installing NodeJS"

id roboshop &>> $LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Adding roboshop system user"
else
    echo -e "Roboshop system user already exists ... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "Creating /app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "Downloading catalogue application code"

cd /app
VALIDATE $? "Changing directory to /app"

rm -rf /app/*
VALIDATE $? "Cleaning /app directory"

unzip /tmp/catalogue.zip &>> $LOGS_FILE
VALIDATE $? "Extracting catalogue application code"

npm install &>> $LOGS_FILE
VALIDATE $? "Installing catalogue application dependencies"

cp $SCRIPT_DIRE/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue service file"

systemctl daemon-reload 

systemctl enable catalogue &>> $LOGS_FILE
systemctl start catalogue 
VALIDATE $? "Starting catalogue service"

cp $SCRIPT_DIRE/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y

mongosh --host $MONGODB_HOST </app/schema/catalogue.js &>> $LOGS_FILE