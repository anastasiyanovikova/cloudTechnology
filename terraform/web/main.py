import requests
from flask import Flask, request, render_template

app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False

url = open("urllogic.txt", "r").readline()
urlrequest = "http://"+url+":5000/getVacancies"

@app.route('/', methods=['post', 'get'])
def findVacancyName():
    result = {}
    if request.method == 'POST':
        vac_name = request.form.get('name')
        city = request.form.get('city')

        print(vac_name, city)
        if vac_name and city:
            results = requests.get(urlrequest, params={'name': vac_name, 'city': city})
            result = results.json()

    return render_template('showVacancyByName.html', **result)

if __name__ == "__main__":
    app.run()
