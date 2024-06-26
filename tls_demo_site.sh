project="cp_demo_server"
mkdir "${project}_project"
cd "${project}_project/"
mkdir $project
mkdir $project/certificate/
sudo apt install python3-virtualenv -y
virtualenv venv
source venv/bin/activate
pip install flask flask-wtf

touch $project/certificate/openssl.cnf

cat >> $project/certificate/openssl.cnf <<EOF
[ req ]
prompt = no
distinguished_name = americas-ses.com

[ americas-ses.com ]
countryName=            CA
stateOrProvinceName=    ON
localityName=           Ottawa
organizationName=       server.Americas-ses
organizationalUnitName= Demo TLS Web Server
commonName=             www.server.americas-ses.ca
emailAddress = kalshaww@checkpoint.com
EOF


# You can generate self-signed certificates easily from the command line. All you need is to have openssl installed:
# sudo apt install openssl
openssl req -x509 --config $project/certificate/openssl.cnf -newkey rsa:4096 -nodes -out $project/certificate/cert.pem -keyout $project/certificate/key.pem -days 365
openssl pkcs12 -export -out $project/certificate/cp_demo_server.p12 -inkey $project/certificate/key.pem -in $project/certificate/cert.pem -passout pass:vpn123!


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
from flask import render_template, jsonify, send_file
import ipaddress
@app.route("/", methods=["get"])
@app.route("/index.html", methods=["get"])
def index():
    return render_template('index.html')

@app.route('/download_cert')
def download_cert ():
    #vFor windows you need to use drive name [ex: F:/cert.pem]
    path = "certificate/cp_demo_server.p12"
    return send_file(path, as_attachment=True)
        
@app.route("/get-json", methods=["get"])
def get_json():
    ranges = ["americas-ses.com"]
    dc = {
        "objects": [
            {
                "name": "Network Feed - Json Format",
                "ranges": ranges,
            }
        ],
    }

    for ip in range(0x0A0002AA, 0x0A0002AA + 5):
        ranges.append(str(ipaddress.IPv4Address(ip)))
    return jsonify(dc)


@app.route("/get-list", methods=["get"])
def get_list():
    delimiter = ","
    ignores_lines_with_prefix = "#"
    delimiter += " \n"
    ignores_lines_with_prefix += " this line should be ignoreed"

    dc = ["example.net", ignores_lines_with_prefix]

    for ip in range(0xC0A80100, 0xC0A80100 + 10):
        dc.append(str(ipaddress.IPv4Address(ip)))

    return delimiter.join(dc)


@app.route("/get-gdc", methods=["get"])
def get_gdc():
    dc = {
        "version": "1.0",
        "description": "Generic Data Center JSON file Example",
        "objects": [
            {
                "name": "GDC IPv4 Ranges",
                "id": "e7f18b60-f22d-4f42-8dc2-050490ecf6d5",
                "description": "Example for IPv4 addresses",
                "ranges": [
                    "91.198.174.192",
                    "20.0.0.0/24",
                    "1.1.1.1",
                    "1.2.3.4",
                    "10.1.1.2-10.1.1.10",
                ],
            },
            {
                "name": "GDC IPv6 Ranges",
                "id": "a46f02e6-af56-48d2-8bfb-f9e8738f2bd0",
                "description": "Example for IPv6 addresses",
                "ranges": [
                    "2001:0db8:85a3:0000:0000:8a2e:0370:7334",
                    "0064:ff9b:0000:0000:0000:0000:1234:5678/96",
                    "2001:0db8:85a3:0000:0000:8a2e:2020:0-2001:0db8:85a3:0000:0000:8a2e:2020:5",
                ],
            },
        ],
    }
    return jsonify(dc)

EOF
cat > run.py << EOF
import os
import sys
sys.path.append(os.path.dirname(os.getcwd()))
from $project import app
if __name__ == '__main__':
    app.run(host ='0.0.0.0', port='8080', debug=True, ssl_context=('certificate/cert.pem', 'certificate/key.pem'))
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
 	<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3" crossorigin="anonymous">

        <div class="container">

        </br>
        <h3>Demo Servers for Generic Datacenter Objects and Network Feeds</h3>
        </br>
        <form method="get" action="/get-json">
            <button type="submit" class="btn btn-info">Network Feed - JSON</button>
        </form>
        </br>
        <form method="get" action="/get-list">
            <button type="submit" class="btn btn-primary">Network Feed - Flat List</button>
        </form>
        </br>
        <form method="get" action="/get-gdc">
            <button type="submit" class="btn btn-secondary">Generic Gata Center Feed</button>
        </form>
        
    </div>
    
    <div class="container">
        </br></br>
        <h3>Server with certificate for Inbound HTTPS Inspection</h3>
        </br>
	<form method="get" action="/download_cert">
            <button type="submit" class="btn btn-warning">Download the Server Certificate (pass:vpn123!)</button>
        </form>
        
    </div> 
{% endblock %}
EOF
pip freeze > requirements.txt
python3 run.py
