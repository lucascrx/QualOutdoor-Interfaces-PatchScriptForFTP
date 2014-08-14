#!/bin/bash


DIR=/home/pc-alsett/Bureau/testFTP/DIRclient/myUploads


while change=$(inotifywait -e close_write $DIR --format %f .); do
	echo $change;
	echo "$DIR/$change";
	
	control=${change:0:4}
	echo "new file recieved $change";

	if [ "$control" = "file" ];
 	then
		#on remplace les champs du fichier pour préparer le LOAD DATA INFILE
		#on utilise le module "sed"
		 
		sed -i -E 's,\$,///;,g' $DIR/$change ;
		echo "ok 1!"
		cat "$DIR/$change";
		echo "hop!";
		sed -i -E 's/\#(.+)#//g' $DIR/$change ;
		echo "ok 2!"
		cat "$DIR/$change";
		
		echo "file modified";
		
		#on charge le fichier dans une table temporaire
		/usr/bin/mysql  --user="ftp" --password="passftp" --database="qualoutdoor_db" 			--execute="
		create table table_upload_temp_$change (LINE INT NOT NULL AUTO_INCREMENT PRIMARY 			KEY ,LVL INT NOT NULL, REFERENCE BIGINT NOT NULL, LAT REAl, LNG REAL, MEAS_DATA VARCHAR	(100) );
		
		LOAD DATA LOCAL INFILE '$DIR/$change' INTO TABLE table_upload_temp_$change FIELDS TERMINATED BY '/' LINES TERMINATED BY ';' (LVL , REFERENCE , LAT , LNG , MEAS_DATA);

		CALL proc_tree('table_upload_temp_$change');"
 
	echo "data stored in db";
		#on appelle le trigger qui traitera cette table pour recreer l'arbre intervallaire
	
	
	fi
done
