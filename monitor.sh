#!/bin/bash


DIR=/home/pc-alsett/Bureau/testFTP/DIRclient/myUploads


while change=$(inotifywait -e close_write $DIR --format %f .); do
	echo $change;
	echo "$DIR/$change";
	
	control=${change:0:4}
	echo "new file recieved $change";

	if [ 1 ];#"$control" = "file" ];
 	then
		#on decompresse l'archive:
		randomNb=$(( $RANDOM % 8999 + 1000 ));
		folder=DIR_$change$randomNb;
		echo "folder ";
		echo "$folder ";
		extractDIR=$DIR/$folder;
		echo "extractDIR ";
		echo "$extractDIR";
		unzip $DIR/$change -d $extractDIR ;
		
		for entry in $extractDIR/*;
		do
		echo "$entry";
		#on remplace les champs du fichier pour préparer le LOAD DATA INFILE
		#on utilise le module "sed"
		 
		sed -i -E 's,\$,///;,g' $entry ;
		echo "ok 1!"
		cat "$DIR/$change";
		echo "hop!";
		sed -i -E 's/\#(.+)#//g' $entry ;
		echo "ok 2!"
		cat "$DIR/$change";
		
		echo "file modified ";
		
		fileName=$(basename $entry);
		
		completeName=$folder$fileName;
		
		echo "CN : $completeName";
		
		
		#on charge le fichier dans une table temporaire
		/usr/bin/mysql  --user="ftp" --password="passftp" --database="qualoutdoor_db" 			--execute="
		create table temp_$completeName (LINE INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,LVL INT NOT NULL, REFERENCE BIGINT NOT NULL, LAT REAl, LNG REAL, MEAS_DATA VARCHAR	(100) );
		
		
		
		LOAD DATA LOCAL INFILE '$entry' INTO TABLE temp_$completeName FIELDS TERMINATED BY '/' LINES TERMINATED BY ';' (LVL , REFERENCE , LAT , LNG , MEAS_DATA);
	
		
		
		CALL proc_tree('temp_$completeName');"
	
		
		
	echo "data stored in db";
		
		done
	
	fi
done
