#!/usr/bin/python2
# -*- coding:utf-8 -*-

import sys
reload(sys)
import urllib2
import json
import os
import time
import re

sys.setdefaultencoding('utf-8')

LOCATION = ['128400']	# Location codes from the isd file
KEY = '***KEY***'	# Forecast.io API key
WPATH = '/home/user/.conky'		# Path of weather files
XMLFILE = WPATH+'/weather{0:d}.xml'	# Location of weather xml file
ISDFILE = WPATH+'/isd.csv'		# ISD location codes, city names and coordinates
CITY = ''			# Default city name
LAT = ''			# Default latitude
LON = ''			# Default longitude
WURL = 'https://api.darksky.net/forecast/'+KEY+'/{0:s},{1:s}?units=si&lang=hu&exclude=hourly,minutely' # Forecast.io API URL
UPDTIME = 1800				# Weather update time in seconds

STR_MONTH = ('', 'Január', 'Február', 'Március', 'Április', 'Május', 'Június',
    'Július', 'Augusztus', 'Szeptember', 'Október', 'November', 'December')

STR_WEEKN = ('Hétfő', 'Kedd', 'Szerda', 'Csütörtök', 'Péntek', 'Szombat',
    'Vasárnap')

# Integer convertation
def conv_int(txt):
    try:
	return int(round(float(txt)))
    except:
	return 0

# Float convertation
def conv_float(txt):
    try:
	return float(txt)
    except:
	return 0.0


def conv_icon(cur):
    icons = []
    if cur['icon'] in ('clear-day', 'partly-cloudy-day', 'wind'):
	icons.append('e_sun')
    elif cur['icon'] in ('clear-night', 'partly-cloudy-night'):
	try:
	    mp = cur['moonPhase']
	except:
	    icons.append('e_moon')
	else:
	    icons.append('e_sun')
    if cur['icon'] in ('partly-cloudy-day', 'partly-cloudy-night', 'wind'):
	if cur['cloudCover'] >= 0.4:
	    icons.append('e_mostly')
	elif cur['cloudCover'] >= 0.1:
	    icons.append('e_partly')
    elif cur['icon'] in ('cloudy', 'rain', 'snow', 'sleet'):
	icons.append('e_cloud')
    elif cur['icon'] == 'fog':
	icons.append('e_fog')
    if (cur['icon'] == 'wind') or (cur['windSpeed'] >= 10.8):
	icons.append('e_wind')
    if cur['icon'] == 'snow':
	if cur['precipIntensity'] >= 0.25:
	    icons.append('e_heavysnow')
	icons.append('e_snow')
    if cur['icon'] == 'rain':
	if cur['precipIntensity'] >= 0.25:
	    icons.append('e_heavyrain')
	icons.append('e_rain')
    if cur['icon'] == 'sleet':
	if cur['precipIntensity'] >= 0.25:
	    icons.append('e_heavyrain')
	    icons.append('e_heavysnow')
	icons.append('e_rain')
	icons.append('e_snow')
    return icons

def conv_wind(cur):
    if cur['windSpeed'] < 1.5:
	wind_s = 0
    elif cur['windSpeed'] < 5.5:
	wind_s = 1
    elif cur['windSpeed'] < 10.8:
	wind_s = 2
    elif cur['windSpeed'] < 17.2:
	wind_s = 3
    else:
	wind_s = 4
    return [wind_s, cur['windBearing'], "{0:1.0f} km/h".format(conv_int(cur['windSpeed']*3.6))]

def conv_qpf(cur):
    p = conv_int(cur['precipProbability']*10)
    if p > 0:
	try:
	    qpf = (cur['precipIntensity']*2+cur['precipIntensityMax'])*8
	except:
	    qpf = cur['precipIntensity']*24
	if cur['precipType'] == 'snow':
	    if qpf >= 1.0:
		res = [p, 1, "{0:d} cm".format(conv_int(qpf))]
	    else:
		res = [p, 1, "<1 cm"]
	elif cur['precipType'] == 'sleet':
	    if qpf >= 1.0:
		res = [p, 2, "{0:1.0f} mm".format(qpf)]
	    else:
		res = [p, 2, "<1 mm"]
	else:
	    if qpf >= 1.0:
		res = [p, 0, "{0:1.0f} mm".format(qpf)]
	    else:
		res = [p, 0, "<1 mm"]
    else:
	res = [0, 0, '---']
    return res

def conv_summary(cur):
    reg = { '\(under ([0-9]+)cm\)': '(<{0:s}cm)',
	    '\(under ([0-9]+) cm.\)': '(<{0:s}cm)',
    }

    dic = { 'Drizzle in the morning and overnight': 'Szitálás',
	    'Drizzle starting in the afternoon': 'Délutáni szitálás',
	    'Drizzle overnight': 'Éjszakai szitálás',
	    'Light rain until evening': 'Enyhe eső estig',
	    'Mixed precipitation overnight': 'Éjszakai vegyes csapadék',
	    'Light rain starting in the afternoon': 'Enyhe eső délután',
	    'Light rain throughout the day': 'Enyhe eső egész nap',
	    'Mostly cloudy throughout the day': 'Erősen felhős egész nap',
	    'throughout the day': 'egész nap',
	    'starting in the afternoon, continuing until evening': 'délutántól estig',
	    'starting in the afternoon': 'délutántól',
	    'starting in the evening': 'estétől',
	    'starting again overnight': 'éjszaka újra',
	    'starting again in the evening': 'estétől újra',
	    'in the morning': 'reggel',
	    'in the afternoon': 'délután',
	    'and overnight': 'és éjszaka',
	    'overnight': 'éjszaka',
	    'until afternoon': 'délutánig',
	    'until evening': 'estig',
	    'breezy': 'szeles',
	    ' and': ',',
	    'evening': 'este',
	    'afternoon': 'délután',
	    'Mixed precipitation': 'Vegyes csapadék',
	    'Drizzle': 'Szitálás',
	    'Light rain': 'Enyhe eső',
	    'light rain': 'enyhe eső',
	    'Light snow': 'Enyhe hó',
	    'Light Rain': 'Enyhe eső',
	    'Overcast': 'Felhős',
	    'Breezy': 'Szeles',
	    'Foggy': 'Ködös',
	    'Windy': 'Szeles',
	    'windy': 'szeles',
	    'Clear': 'Tiszta',
	    'Flurries': 'Hózápor',
	    'mostly cloudy': 'erősen felhős',
	    'Partly cloudy': 'Helyenként felhős',
	    'Mostly cloudy': 'Erősen felhős',
	    'Partly Cloudy':'Helyenként felhős',
	    'Mostly Cloudy': 'Erősen felhős',
	    'Rain': 'Eső'
    }
    pattern = re.compile("|".join([re.escape(k) for k in dic.keys()]), re.M)
    text = pattern.sub(lambda x: dic[x.group(0)], cur)
    for i, j in reg.items():
	pattern = re.compile(i)
	text =  pattern.sub(lambda x: j.format(x.group(1)), text)
    return text


def write_xml(result):
    data = {}
    wdate = time.localtime(result['currently']['time'])
    data['city'] = CITY
    data['location'] = "{0:4.2f}:{1:4.2f}".format(result['latitude'], result['longitude'])
    data['time'] = "{0:4d}-{1:02d}-{2:02d} {3:2d}:{4:02d}".format(wdate[0], wdate[1], wdate[2], wdate[3], wdate[4])
    data['temp'] = conv_int(result['currently']['temperature'])
    data['icon'] = conv_icon(result['currently'])
    data['weather'] = conv_summary(result['currently']['summary'])
    data['cloud'] = "{0:2d} %".format(conv_int(result['currently']['cloudCover']*100))
    data['pressure'] = "{0:4d} mb".format(conv_int(result['currently']['pressure']))
    data['wind'] = conv_wind(result['currently'])
    data['humidity'] = "{0:2d} %".format(conv_int(result['currently']['humidity']*100))
    data['dewpoint'] = "{0:2d} °C".format(conv_int(result['currently']['dewPoint']))
    data['qpf'] = conv_qpf(result['currently'])

    data['f_icon'] = []
    data['f_htemp'] = []
    data['f_ltemp'] = []
    data['f_weather'] = []
    data['f_date'] = []
    data['f_qpf'] = []
    data['f_wind'] = []
    data['f_humidity'] = []
    data['f_pressure'] = []
    data['f_dewpoint'] = []
    data['f_cloud'] = []

    cur_f = (result['daily']['data'][0], result['daily']['data'][1],
	    result['daily']['data'][2], result['daily']['data'][3],
	    result['daily']['data'][4])

    for i in range(0, 5):
	data['f_icon'].insert(i, conv_icon(cur_f[i]))
	data['f_htemp'].insert(i, conv_int(cur_f[i]['temperatureMax']))
	data['f_ltemp'].insert(i, conv_int(cur_f[i]['temperatureMin']))
	if len(cur_f[i]['summary']) > 32:
	    data['f_weather'].insert(i, "{0:s}...".format(cur_f[i]['summary'][:32]))
	else:
	    data['f_weather'].insert(i, cur_f[i]['summary'])
	fdate = time.localtime(cur_f[i]['time'])
	data['f_date'].insert(i, "{0:s} {1:d} ({2:s})".format(STR_MONTH[fdate[1]], fdate[2], STR_WEEKN[fdate[6]]))
	data['f_wind'].insert(i, conv_wind(cur_f[i]))
	data['f_qpf'].insert(i, conv_qpf(cur_f[i]))
	data['f_humidity'].insert(i, "{0:2d} %".format(conv_int(cur_f[i]['humidity']*100)))
	data['f_pressure'].insert(i, "{0:4d} mb".format(conv_int(cur_f[i]['pressure'])))
	data['f_dewpoint'].insert(i, "{0:2d} °C".format(conv_int(cur_f[i]['dewPoint'])))
	data['f_cloud'].insert(i, "{0:2d} %".format(conv_int(cur_f[i]['cloudCover']*100)))
    return data

def get_data(isd):
    global CITY, LAT, LON
    if os.path.isfile(ISDFILE):
	fi = open(ISDFILE, 'r')
	for line in fi.read().splitlines():
	    row = line.split(',')
	    if row[0] == isd:
		LAT = row[4]
		LON = row[5]
		CITY = row[1]+', '+row[2]
		break
	fi.close()
    f = urllib2.urlopen(WURL.format(LAT,LON))
    result = json.loads(f.read())
    f.close()
    return result

#==============================================================================
# Main program
#==============================================================================

for i in range(0,len(LOCATION)):
    fname = XMLFILE.format(i)
    if (not os.path.isfile(fname)) or (time.time() >= os.stat(fname).st_mtime+UPDTIME):		# nothing XML file
    	result = get_data(LOCATION[i])
#    	result = eval(file(WPATH+'/'+LOCATION[i]+'.xml', 'r').read())
	data = write_xml(result)
	file(fname, 'w').write(json.dumps(data))
#	file(WPATH+'/'+LOCATION[i]+'.xml', 'w').write(repr(result))
