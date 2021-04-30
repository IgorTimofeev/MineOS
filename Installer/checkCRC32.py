import slpp,binascii

with open('Files.cfg') as f:
	files=slpp.slpp.decode(f.read())

obj={}
for i in files.values():
	for j in i:
		if type(j)==dict:
			path=j['path']
		else:
			path=j
		with open("../"+path,'rb') as f:
			data=f.read()
			crc32=binascii.crc32(data)
		print(f"path:{path} crc32:{hex(crc32)}")
		obj[path]={'crc32':crc32,'length':len(data)}
with open('crc32.cfg','w') as f:
	f.write(slpp.slpp.encode(obj))