# ricevere notifica via mail del livello inchiostro nella stampante

parametri da impostare in inchiostro.sh
1) cd /home/persorso -> con il proprio percorso 
2) ip_stampante -> con ip server propria stampante
3) indirizzo_mail -> con indirizzo email destinatario 

funzionamento
1) "inchiostro.sh" chiama il server della stampante ed estrae la percentuale d'inchiostro (vedi pdf)
2) i valori della percentuale verranno inseriti nel file "data_nuovo.txt" e comparati con quelli in "data.txt"
3) se si è verificato un calo verrà copiato il contenuto di "originale.html" in "spedisci-mail.html" 
4) all'interno di "spedisci-mail.html" verranno sostituiti i parametri. 
  * MMMM -> percentuale inchiostro magenta contenuto in "data_nuovo.txt"
  * CCCC -> percentuale inchiostro ciano contenuto in "data_nuovo.txt"
  * GGGG -> percentuale inchiostro giallo contenuto in "data_nuovo.txt"
  * NNNN -> percentuale inchiostro nero contenuto in "data_nuovo.txt"
 5) invio mail

# ricordati di avere installato un server mail smtp sulla macchina 
server smtp link utile: https://www.tosolini.info/2015/10/postfix-modo-satellite-e-smtp-con-gmail/


# se spedisci la notifica verso Gmail  
guarda questa guida : https://www.emailonacid.com/blog/article/email-development/12_things_you_must_know_when_developing_for_gmail_and_gmail_mobile_apps-2/
