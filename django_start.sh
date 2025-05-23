#!/bin/bash

#   Variable Data
ProjectName=" "     # supplement your Project Name
AppName=""          # supplement your App Name
Git_ProjectURL=""   # supplement your Git_ProjectURL Name
RootPath="/ "       # supplement your Path to your websites

#   Constant Data
ProjectPath=$RootPath/$ProjectName
VenvName="venv"

Template=$(cat <<EOF

EOF
)

Skeleton=$(cat <<EOF
{% load static %}

<!DOCTYPE html>
<html>
<head>
    <title> {% block title %}{% endblock %}</title>
    <link rel="stylesheet", href="{% static "$ProjectName/css/main.css" %}">
    {% block css_sheets %}{% endblock %}
</head>
<body>
    <div class="header">
        {% block header %}
        {% include "header.html" %}
        {% endblock %}
    </div>
    <div class="sidebar">
        {% block sidebar %}
        {% include "sidebar.html" %}
        {% endblock %}
    </div>
    <div class="content">
        {% block content %}
        {% endblock %}
    </div>
    <div class="advertising">
        {% block advertising %}
        {% include "advertising.html" %}
        {% endblock %}
    </div>
    <div class="footer">
        {% block footer %}
        {% include "footer.html" %}
        {% endblock %}
    </div>

    <script src="{% static "$ProjectName/js/main.js" %}"></script>
    {% block js_scripts %}{% endblock %}
</body>
</html>

EOF
)

Advertising=$(cat <<EOF
{% block advertising %}

<p>advertising</p>

{% endblock %}

EOF
)

Footer=$(cat <<EOF
{% block footer %}

<p>This is the footer of my website.</p>

{% endblock %}

EOF
)

Header=$(cat <<EOF
{% block header %}

<h1>$ProjectName</h1>

<p>This is the header of my website.</p>

{% endblock %}

EOF
)

Sidebar=$(cat <<EOF
{% block sidebar %}

<p>Sidebar</p>

{% endblock %}

EOF
)

LandingPageFile=$(cat <<EOF
{% extends "skeleton.html" %}
{% load static %}

{% block title %} $ProjectName $AppName {% endblock %}
{% block css_sheets %}
<link rel="stylesheet", href="{% static "$AppName/css/$AppName.css" %}">
{% endblock %}

{% block content %}

<p>Here you will see my website.</p>
<p>...later</p>
<p>... maybe in some days...</p>
<p>... or weeks :p</p>

{% endblock %}

{% block js_scripts %}
<script src="{% static "$AppName/js/$AppName.js" %}"></script>
{% endblock %}

EOF
)

LandingUrls=$(cat <<EOF
from django.urls import path

from . import views

urlpatterns = [
    path('', views.landingpage, name='landingpage')     # Todo: change landingpage to a variable ?Maybe?
]

EOF
)

LandingViews=$(cat <<EOF
from django.shortcuts import render

from django.http import HttpResponse
from django.template import loader

# Create your views here.
def landingpage(request):
    template = loader.get_template('landingpage.html')
    return HttpResponse(template.render())

EOF
)

MainCss=$(cat <<EOF
:root{
    --sc_middle: 2;
    --ca_middle: 8;
    --end: 9;
}

body {
    max-width: 61%;
    margin: auto;
    display: grid;
    grid-template-columns: repeat(12%, 8);
    gap: 5px;

    background-color: lightseagreen;
}

.header {
    grid-column: 1/var(--end);
    grid-row: 1/2;
    
    background-color: rgb(42, 13, 109);
}

.sidebar {
    grid-column: 1/var(--sc_middle);
    grid-row: 2/span 4;
    
    background-color: rgb(42, 13, 109);
}

.content{
    min-height: 50em;
    grid-column: var(--sc_middle)/8;
    grid-row: 2/span 3;
    
    background-color: rgb(67, 19, 179);
}

.advertising{
    grid-column: var(--ca_middle)/var(--end);
    grid-row: 2/span 3;
    
    background-color: rgb(107, 71, 192);
}

.footer {
    grid-column: var(--sc_middle)/var(--end);
    grid-row: 5/6;
    
    background-color: rgb(42, 13, 109);
}

EOF
)

LandingCss=$(cat <<EOF
.content p {
    color: bisque;
}
EOF
)

Requirements=$(cat <<EOF
Django
python-dotenv
psycopg2-binary
EOF
)

GitIgnore=$(cat <<EOF
venv
__pycache__
*.sqlite3

EOF
)

#   1. Prepare Debian for Django by installing packages.
# apt update && upgrade
sudo apt install build-essential
sudo apt install python3
sudo apt install python3-pip
sudo apt install python3-venv
sudo apt install git

#   2. Create and Prepare an virtual Environment
mkdir $ProjectPath
cd $ProjectPath

python3 -m venv $VenvName
source venv/bin/activate

echo "$Requirements" > $ProjectPath/requirements.txt
pip install -r requirements.txt

#   3. Create and prepare Project
django-admin startproject $ProjectName

mkdir $ProjectPath/$ProjectName/$ProjectName/templates
echo "$Skeleton" > $ProjectPath/$ProjectName/$ProjectName/templates/skeleton.html
echo "$Advertising" > $ProjectPath/$ProjectName/$ProjectName/templates/advertising.html
echo "$Footer" > $ProjectPath/$ProjectName/$ProjectName/templates/footer.html
echo "$Header" > $ProjectPath/$ProjectName/$ProjectName/templates/header.html
echo "$Sidebar" > $ProjectPath/$ProjectName/$ProjectName/templates/sidebar.html

sed -i "s/'DIRS': \[\]/'DIRS': \[BASE_DIR\/\"$ProjectName\"\/\"templates\"\]/" $ProjectPath/$ProjectName/$ProjectName/settings.py
sed -i "/STATIC_URL/aSTATICFILES_DIRS = \[ BASE_DIR \/ \"static\" \]" $ProjectPath/$ProjectName/$ProjectName/settings.py
sed -i "/django.contrib/afrom django.urls import include" $ProjectPath/$ProjectName/$ProjectName/urls.py

#   4. Create App and add some folders and files
cd $ProjectPath/$ProjectName
python3 manage.py startapp $AppName
mkdir $ProjectPath/$ProjectName/$AppName/templates/
echo "$LandingPageFile" > $ProjectPath/$ProjectName/$AppName/templates/landingpage.html
echo "$LandingUrls" > $ProjectPath/$ProjectName/$AppName/urls.py
echo "$LandingViews" > $ProjectPath/$ProjectName/$AppName/views.py

#   4.1 Connect App with Project
sed -i "/INSTALLED_APPS/a\\\t'$AppName',\n" $ProjectPath/$ProjectName/$ProjectName/settings.py
sed -i "/urlpatterns = /a\\\tpath('', include('$AppName.urls')),\n" $ProjectPath/$ProjectName/$ProjectName/urls.py

#   5. Create static folder and content
mkdir $ProjectPath/$ProjectName/static/
mkdir $ProjectPath/$ProjectName/static/$ProjectName/
mkdir $ProjectPath/$ProjectName/static/$ProjectName/css
echo "$MainCss" > $ProjectPath/$ProjectName/static/$ProjectName/css/main.css
mkdir $ProjectPath/$ProjectName/static/$ProjectName/js
echo "console.log(\"You are in the Skeleton\", main.js);" > $ProjectPath/$ProjectName/static/$ProjectName/js/main.js
mkdir $ProjectPath/$ProjectName/static/$ProjectName/media


mkdir $ProjectPath/$ProjectName/static/$AppName/
mkdir $ProjectPath/$ProjectName/static/$AppName/css
echo "$LandingCss" > $ProjectPath/$ProjectName/static/$AppName/css/$AppName.css
mkdir $ProjectPath/$ProjectName/static/$AppName/js
echo "console.log(\"You are on the Landigpage\", $AppName.js);" > $ProjectPath/$ProjectName/static/$AppName/js/$AppName.js
mkdir $ProjectPath/$ProjectName/static/$AppName/media

# Todo: git
git init
git branch -M main
echo "$GitIgnore" > $ProjectPath/.gitignore
git add *
git add .gitignore
git commit -m "initial commit"
git remote add origin $Git_ProjectURL
git push -u origin main
