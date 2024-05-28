project="demo_site"
mkdir "${project}_project"
cd "${project}_project/"
mkdir $project
mkdir $project/certificate/
virtualenv venv
source venv/bin/activate
pip install flask flask-wtf

# You can generate self-signed certificates easily from the command line. All you need is to have openssl installed:
# sudo apt install openssl
openssl req -x509 -newkey rsa:4096 -nodes -out $project/certificate/cert.pem -keyout $project/certificate/key.pem -days 365

cd $project
mkdir static templates data
touch forms.py
cat > __init__.py << EOF
from flask import Flask
app = Flask(__name__)
from $project import views
EOF
cat > views.py << EOF
from $project import app
from flask import render_template
@app.route('/')
def index():
    return render_template('index.html')
EOF
cat > run.py << EOF
import os
import sys
sys.path.append(os.path.dirname(os.getcwd()))
from $project import app
if __name__ == '__main__':
    app.run(debug=True, ssl_context=('$project/certificate/cert.pem', '$project/certificate/key.pem'))
EOF
cat > templates/base.html << 'EOF'
<!DOCTYPE html>
<html>
    <head>
    {% block head %}
    {% endblock %}
    </head>
    
    <body>
    {% block content %}
    {% endblock %}
    </body>
</html>
EOF
cat > templates/index.html << EOF
{% extends 'base.html' %}
{% block content %}
    <h1>$project</h1>
{% endblock %}
EOF
pip freeze > requirements.txt
python run.py
