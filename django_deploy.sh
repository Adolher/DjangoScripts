#!/bin/bash

#   Variable Data
ProjectName=""     # supplement your Project Name
DomainName=""      # supplement your Domain name
Git_ProjectURL=""  # supplement the repository url
AdminEMail=""      # supplement your E-Mail for ssl-certificate
RootPath=""       # supplement your Path to your websites
ALLOWED_HOSTS=""

#   Constant Data
ProjectPath=$RootPath/$ProjectName
ProjectUser="$ProjectName"_user
ProjectGroup="$ProjectName"_group

#   File Data
GunicornStart=$(cat <<EOF
#!/bin/bash

NAME=$ProjectName
DJANGODIR=$ProjectPath/$ProjectName
SOCKFILE=$ProjectPath/run/gunicorn.sock
USER=$ProjectUser
GROUP=$ProjectGroup
NUM_WORKERS=`nproc`
DJANGO_SETTINGS_MODULE=$ProjectName.settings
DJANGO_WSGI_MODULE=$ProjectName.wsgi
TIMEOUT=120

cd \$DJANGODIR
source ../venv/bin/activate
export DJANGO_SETTINGS_MODULE=\$DJANGO_SETTINGS_MODULE
export PYTHONPATH=\$DJANGODIR:\$PYTHONPATH

RUNDIR=\$(dirname \$SOCKFILE)
test -d \$RUNDIR || mkdir -p \$RUNDIR

exec ../venv/bin/gunicorn \${DJANGO_WSGI_MODULE}:application \
  --name \$NAME \
  --workers \$NUM_WORKERS \
  --timeout \$TIMEOUT \
  --user=\$USER --group=\$GROUP \
  --bind=unix:\$SOCKFILE \
  --log-level=debug \
  --log-file=-
EOF
)

SuperVisor=$(cat <<EOF
# $ProjectName.conf

[program:$ProjectName]
command = $ProjectPath/venv/bin/gunicorn_start
user = $ProjectUser
stdout_logfile = $ProjectPath/logs/supervisor.log
redirect_stderr = true
environment=LANG=en_US.UTF-8,LC_ALL=en_US.UTF-8
EOF
)

NginX=$(cat <<EOF
upstream $ProjectName.app_server {
    server unix:$ProjectPath/run/gunicorn.sock fail_timeout=0;
}

server {
    listen 80;
    listen [::]:80;
    server_name .$DomainName;
    
    access_log $ProjectPath/logs/access.log;
    error_log $ProjectPath/logs/error.log;
    
    location /static/ {
        alias $ProjectPath/$ProjectName/static/;
    }
    
    location /media/ {
        alias $ProjectPath/$ProjectName/media/;
    }
    
    location / {
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        
        proxy_set_header Host \$http_host;
        
        proxy_redirect off;
        
        if (!-f \$request_filename) {
            proxy_pass http://$ProjectName.app_server;
        }
    }
}
EOF
)


#   1. Prepare Debian for Django deployment
#   1.1 install packages

# apt update && upgrade
#apt install nginx
#apt install certbot
#apt install python3
#apt install python3-pip
#apt install python3-venv 
#apt install python3-certbot-nginx
#apt install supervisor
#apt install git

#   1.2 create user and group

groupadd --system $ProjectGroup
useradd --system --gid $ProjectGroup --shell /bin/bash --home $ProjectPath $ProjectUser

cd $RootPath

#   2. get and prepare the Django Project
#   2.1 get the Django project
git clone $Git_ProjectURL

#   2.2 create and prepare a virtual environment
cd $ProjectPath
python3 -m venv venv
source venv/bin/activate
pip install -r $RootPath/$ProjectName/requirements.txt

#   2.2.1 migrate Database          # Todo
cd $ProjectPath/$ProjectName
python3 manage.py migrate
python3 manage.py makemigrations

#   2.2.2 install and prepare gunicorn
pip install gunicorn
echo "$GunicornStart" > $ProjectPath/venv/bin/gunicorn_start
chmod +x $ProjectPath/venv/bin/gunicorn_start

#   2.2.3 change the ALLOWED_HOSTS
sed -i "s/\[\]/\['$ALLOWED_HOSTS'\]/" $ProjectPath/$ProjectName/$ProjectName/settings.py


#   2.3 prepare supervisor
mkdir $ProjectPath/logs
echo "$SuperVisor" > /etc/supervisor/conf.d/$ProjectName.conf
supervisorctl status

#   2.4 prepare nginx
echo "$NginX" > /etc/nginx/sites-available/$ProjectName.conf
cd /etc/nginx/sites-enabled/
ln -s ../sites-available/$ProjectName.conf
service nginx start
service nginx status
cd $ProjectPath

#   2.5 get ssl certificate
printf "$AdminEMail\ny\nn\n" | certbot -d $DomainName

#   3 Post-Processing
chown -R $ProjectUser:$ProjectGroup $ProjectPath

service nginx restart
service nginx status

supervisorctl restart $ProjectName
supervisorctl status
