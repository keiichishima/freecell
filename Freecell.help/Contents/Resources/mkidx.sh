#!/bin/sh

for lc in en es fi fr ja nl zh-Hans zh-Hant
do
	(
	cd ${lc}.lproj
	hiutil -I lsm -Cf Freecell.helpindex -a -s ${lc} -l ${lc} .
	hiutil -I corespotlight  -Cf Freecell.cshelpindex -a -s ${lc} -l ${lc} .
	)
done
