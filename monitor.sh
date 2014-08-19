#!/bin/bash

DIR=/home/pc-alsett/Bureau/testFTP/DIRclient/myUploads

while change=$(inotifywait -e close_write $DIR --format %f .); do
	echo $change;

		#on decompresse l'archive en lui affectant un nombre aléatoire pour preserver l'unicité:
		randomNb=$(( $RANDOM % 8999 + 1000 ));
		folder=DIR_$change$randomNb;
		extractDIR=$DIR/$folder;
		echo "$extractDIR";
		unzip $DIR/$change -d $extractDIR ;
		
		#pour chaque fichier de l'archive extraite:
		for entry in $extractDIR/*;
		do
			#on remplace les champs du fichier pour préparer le LOAD DATA INFILE
			
			#on utilise le module "sed"
			sed -i -E 's,\$,///;,g' $entry ;
			sed -i -E 's/\#(.+)#//g' $entry ;
			
			#on recupere le nom du fichier pour créer la table
			fileName=$(basename $entry);
			completeName=$folder$fileName;
			
			#on charge le fichier dans une table temporaire
			/usr/bin/mysql  --user="ftp" --password="passftp" --database="qualoutdoor_db" 			--execute="
			create table temp_$completeName (LINE INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,LVL INT NOT NULL, REFERENCE BIGINT NOT NULL, LAT REAl, LNG REAL, MEAS_DATA VARCHAR	(100) );
			LOAD DATA LOCAL INFILE '$entry' INTO TABLE temp_$completeName FIELDS TERMINATED BY '/' LINES TERMINATED BY ';' (LVL , REFERENCE , LAT , LNG , MEAS_DATA);
			CALL proc_tree('temp_$completeName');"
		
			echo "data stored in db";
			
			#on supprime maintenant le fichier du dossier d'extraction
			rm $entry;
			
		done
		
		#on supprime l'archive et le dossier vide
		rm $DIR/$change;
		rmdir $extractDIR;
	

done
