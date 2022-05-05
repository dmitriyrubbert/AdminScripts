#!/usr/bin/python3
# -*- coding:UTF-8 -*-
#
# The script generates json with addresses of bank branches
# Created by goldlinux 5 May 2022 
# --------------------

import requests, json
resultfile='address.json'
url='https://belarusbank.by/api/kursExchange'

r=requests.get(url).json()

addr=[]
for b in r:
	st='улица'
	if b['street_type'] == 'пр.':
		st='проспект'
	elif b['street_type'] == 'ул.':
		st='улица'
	elif b['street_type'] == 'бул.':
		st='бульвар'
	elif b['street_type'] == 'пл.':
		st='площадь'

	nt='город'
	if b['name_type'] == 'г.':
		nt='город'
	elif b['name_type'] == 'трасса':
		nt='трасса'
	elif b['name_type'] == 'г.п.':
		nt='поселок городского типа'
	elif b['name_type'] == 'агрогородок':
		nt='агрогородок'
	elif b['name_type'] == 'п.':
		nt='поселок'

	addr.append({
		"name": b["filials_text"],
		"address": f"{nt} {b['name']}, {st} {b['street']}, дом {b['home_number']}"
		})

with open(resultfile,'w') as f:
	json.dump(addr,f, ensure_ascii=False)