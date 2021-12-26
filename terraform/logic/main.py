import pandas as pd
import requests
from flask import Flask, request


def findVacancies(vac_name, city_name):
    df1 = pd.DataFrame()
    items = requests.get('https://api.hh.ru/suggests/areas?text={}'.format(city_name)).json()['items']
    if items:
        area_id = items[0]['id']
        for i in range(20):
            df1 = df1.append(requests.get(
                'https://api.hh.ru/vacancies?text={}&search_field=name&area={}&per_page=100&page={}'.
                    format(vac_name, area_id, str(i))).json()['items'])
    return df1


def transformSalary(row):
    if row['salary'] is None:
        return 0
    if row['salary']['from'] is not None and row['salary']['to'] is not None:
        sal = (row['salary']['from'] + row['salary']['to']) / 2
    elif row['salary']['from'] is not None:
        sal = row['salary']['from']
    elif row['salary']['to'] is not None:
        sal = row['salary']['to']
    else:
        sal = 0
    cur = row['salary']['currency']
    if cur != 'RUR':
        sal = 0
    return float(sal)


def getResults(vac_name, city):
    df1 = findVacancies(vac_name, city)
    if len(df1) == 0:
        result = {}
        return result
    df1.drop_duplicates('id', inplace=True)
    dftotal = df1[['id', 'name', 'area', 'salary']]
    dftotal['RURSalary'] = dftotal.apply(transformSalary, axis=1)
    dftotal_with_salary = dftotal.loc[dftotal['RURSalary'] > 0]
    avg_salary = dftotal_with_salary['RURSalary'].mean()
    min_salary = dftotal_with_salary['RURSalary'].min()
    max_salary = dftotal_with_salary['RURSalary'].max()
    result = {
        "vac_name": vac_name,
        "city": city,
        "total_vac_count": len(dftotal),
        "vac_with_salary": len(dftotal_with_salary),
        "avg_salary": avg_salary,
        "min_salary": min_salary,
        "max_salary": max_salary
    }
    return result


app = Flask(__name__)
app.config['JSON_AS_ASCII'] = False

@app.route('/')
def index():
    return "hello from docker"

@app.route('/getVacancies', methods=['get'])
def getVacancies():
    vac_name = request.args.get("name")
    city = request.args.get('city')
    print(vac_name, city)
    result = getResults(vac_name, city)
    print(result)
    return result


# app.run(host='127.0.0.1', port=80)
if __name__ == "__main__":
    app.run()
