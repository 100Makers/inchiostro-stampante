#!/bin/bash
#mi sposto nella cartella contenente file html da spedire
cd /home/persorso
# ******************************************* variabili per file dei dati \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
file_html="grezzo.txt" # conterrà la pagina queb della stampante dopo che si è fatto curl 
file_pulito="pulito.txt" # contenente i file estratti
ip_stampante="ip_stampante" # 192.168.x.x

# ******************************************* variabili per la verifica di cambiamento inchiostro rispetto ai dati vecchi  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
file_inchiostro_vecchio="data.txt"
file_inchiostro_nuovo="data_nuovo.txt"

percentuale_inchiostro_di_confronto=5 #numero offset di notifica calo inchiostro dopo che si è superato numero percentuale_minima 
trovato_calo_inchiostro=0 # variabile controllo numero offset, 1 chalo inchiostro dal precedente dato , 0 non calo inchiostro esco da script

# ******************************************** variabili per mail \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

#imposto valore inchiostro minimo prima di inviare mail
percentuale_minima=10 # sopra a questo valore non verrà mai notificato livello inchiostro 

# variabile di controllo nel caso ci sia un colore con inchiostro < percentuale_minima
trovato=0

#creo un'array vuoto che conterrà i colori con valore < percentuale_minima
# i valori contenuti in questo array verranno inseriti nell'oggetto della mail 
messaggio=([1]=" " [2]=" " [3]=" " [4]=" ")

#nome documento html da spedire
spedischi_file_html="spedisci-mail.html"

#indirizzo mail
indirizzo_mail="indirizzo_mail_destinatario"

#creo una copia html dell'originale
# html originale contiene dei parametri (MMMM,CCCC,GGGG,NNNN) verranno sostituiti col numero %inciostro per questo faccio una copia
cp originale.html $spedischi_file_html

# ****************************************** estraggo dato % inchiostro ****************************************

# effettuo un ping indirizzo ip stampante quello che ricevo lo butto nel buco nero (/dev/null) è un file speciale che non memorizza nulla  
if ping -c 1 $ip_stampante &> /dev/null ;then
        #se il ping è andato a buon fine 
	#scarico html pagina web stampante
	curl -s http://$ip_stampante/general/status.html > $file_html
else
        #se il ping non è andato a buon fine esco dallo script
        exit 0
fi

# pulitura HTML stampante
cat $file_html | grep "<td><img src=" > $file_pulito

# estraggo livello caruccia ( % inchiostro di ogni cartuccia )
lik_level=$(cat pulito.txt | grep -o '[0-9]*')

# prendo i dati ottenuti della % inchiostro e li inserisco in data.txt 
# $(echo $lik_level | awk '{print $2} prende la riga 2 della variabile lik_level 
echo "0 Magenta $(echo $lik_level | awk '{print $2}')" > $file_inchiostro_nuovo
echo "1 Ciano $(echo $lik_level | awk '{print $3}')" >> $file_inchiostro_nuovo
echo "2 Giallo $(echo $lik_level | awk '{print $4}')" >> $file_inchiostro_nuovo
echo "3 Nero $(echo $lik_level | awk '{print $5}')" >> $file_inchiostro_nuovo


#****************************************** verifico valore di offset rispetto ai vecchi dati in memoria ******************************

# verifico che ci siano differenze tra i due file tramite il comando diff e getto l'output
if diff -q $file_inchiostro_vecchio $file_inchiostro_nuovo &> /dev/null;then
        #ping ok
        #echo 'uguali';
        exit 0
else
        #ping non trovato
        #echo 'diversi';

	# inserisco il valore della terza colonna del file $file_inchiostro_nuovo nella variabile corrispondente 
	# tale valore indica la % di inchiostro
        magenta=$(sed -n '1p' $file_inchiostro_nuovo | nawk '{print $3}') #sed prende la riga | nawk prende la colonna
        #echo "magenta $magenta"
        ciano=$(sed -n '2p' $file_inchiostro_nuovo | nawk '{print $3}')
        #echo "ciano $ciano"
        giallo=$(sed -n '3p' $file_inchiostro_nuovo | nawk '{print $3}')
        #echo "giallo $giallo"
        nero=$(sed -n '4p' $file_inchiostro_nuovo | nawk '{print $3}')
        #echo "nero $nero"

        # creo una variabile momentanea che contiene il valore vecchio d'inchiostro
	momentanea=$(sed -n '1p' $file_inchiostro_vecchio | nawk '{print $3}')
	#se inchiostro attuale < di inchiostro vecchio + un range scelto da me ( numero offset ) procedo a notificare via mail 
	#se l'inchiostro è > termino lo script
        if (("$magenta" <= "$(($momentanea-$percentuale_inchiostro_di_confronto))"))
        then
                trovato_calo_inchiostro=1
        fi

        momentanea=$(sed -n '2p' $file_inchiostro_vecchio | nawk '{print $3}')
        if (("$ciano" <= "$(($momentanea-$percentuale_inchiostro_di_confronto))"))
	then
                trovato_calo_inchiostro=1
        fi

        momentanea=$(sed -n '3p' $file_inchiostro_vecchio | nawk '{print $3}')
        if (("$giallo" <= "$(($momentanea-$percentuale_inchiostro_di_confronto))"))
        then
                trovato_calo_inchiostro=1
        fi

        momentanea=$(sed -n '4p' $file_inchiostro_vecchio | nawk '{print $3}')
        if (("$nero" <= "$(($momentanea-$percentuale_inchiostro_di_confronto))"))
        then
                trovato_calo_inchiostro=1
        fi
	
	#se l'inchiostro nuovo non rispetta una certa soglia chiudo il programma e non invio la mail 
        if [ $trovato_calo_inchiostro -eq 0 ]
        then
		#prima di uscire sovrascrivo i dati nuovi nel file dei dati vecchi
		cp $file_inchiostro_nuovo $file_inchiostro_vecchio
                exit 0
        fi

fi


#******************************************* invio mail *****************************************************

#cerco se la % di inchiostro è inferiore al valore minimo nel caso lo sia memorizzo il dato nell'array e assegno valore a trovato=1
# sopra ho impostato ogni quanto deve scendere il livello d'inchiostro prima di inviare una notifica (numero di offset)
# qui sotto controllo che l'inchiostro sia sotto una determinata % (percentuale_minima)

# esempio: 	percentuale_minima=10 e inchiostro nero=50% fino a che il nero non scende a 10% non riceverò alcuna notifica
#		quando nero=10% ricevo la prima notifica 
#		se il percentuale_inchiostro_di_confronto=5 (valore di offset) la seconda notifica di calo inchiostro 
#		la riceverò quando nero=5

#		se il percentuale_inchiostro_di_confronto=4 (valore di offset) la seconda notifica di calo inchiostro
#		la riceverò quando nero=6

if [ $magenta -lt $percentuale_minima ]
then
	trovato=1
	messaggio[1]="Magenta= $magenta %"
fi

if [ $ciano -lt $percentuale_minima ]
then
	trovato=1
	messaggio[2]="Ciano= $ciano %"
fi

if [ $giallo -lt $percentuale_minima ]
then
	trovato=1
	messaggio[3]="Giallo= $giallo %"
fi

if [ $nero -lt $percentuale_minima ]
then
	trovato=1
        messaggio[4]="Nero= $nero %"
fi

#nel caso ci sia  un colore con inchiostro minore del limite provvedo a notificarlo tramite mail
if [ $trovato -eq 1 ]
then
	#vado all'interno del file html da inviare e associo la % di inchiostro nei campi adeguati
	#in questo modo html creerà un grafico basando l'altezza sulla % di inchiostro
	sed -i "s/MMMM/$magenta/g" $spedischi_file_html
	sed -i "s/CCCC/$ciano/g" $spedischi_file_html
	sed -i "s/GGGG/$giallo/g" $spedischi_file_html
	sed -i "s/NNNN/$nero/g" $spedischi_file_html

	#invio la mail indicando
	#metto nell'oggetto della mail inchiostri < percentuale_minima  
	#la data serve in modo che cambi sempre l'oggetto in questo modo evito che gmail riunisca le mail con oggetti uguali in questo modo il grafico sarà visibile appena si apre la mail  
	#se gmail accorpa troppe mail con oggetti unguali il grafico non verrà visualizzato quando si apre la mail questo si chiama : clipping mail
	mail -a "Content-type: text/html;" -s "inchiostro basso per:${messaggio[1]} ${messaggio[2]} ${messaggio[3]} ${messaggio[4]}  $(date +%d/%m/%Y)" $indirizzo_mail1 < $spedischi_file_html

fi

#******************************* rimuovo file in eccesso e copio dati nuovi in dati vecchi //////////////////////////////////////

rm $file_html $file_pulito
cp $file_inchiostro_nuovo $file_inchiostro_vecchio

