#!/bin/bash

# Autore: GjMan78 per forum.ubuntu.it.org

# Ultimo aggiornamento: 01-12-2023

# Script PARECCHIO work in progress. 

# DA IMPLEMENTARE: 
# 
# - funzioni utili per il forum (diagnosi aggiornamenti - diagnosi rete)

# ls -l /etc/apt/sources.list.d | awk '{ print $9 }'

# DA MIGLIORARE: pulizia file temporanei


# Log eventi
InizializzaLog () {

utente=${SUDO_USER}
percorso="/home/${utente}/.config/puliziaubuntu/"
nomefile=$(date +%Y-%m-%d)
logfile="${percorso}${nomefile}.log"

# crea la cartella delle configurazioni se non esiste
if [ ! -d ${percorso} ]; then
  sudo -u ${utente} mkdir ${percorso}
else
# elimina log più vecchi di 7 giorni (se esistono)
  find ${percorso} -type f -mtime +7 -name '*.log' -print0 | xargs -r0 rm -- > /dev/null
fi

}


# Consenso informato

Disclaimer () {

dialog \
  --backtitle "Dichiarazione di NON responsabilità" \
  --title "LEGGI BENE!" \
  --msgbox "L'autore declina ogni responsabilità per eventuali danni diretti o indiretti e/o malesseri fisici \
	o psicologici causati dallo script.\n\nProseguendo accetti di utilizzare il software fornito a tuo rischio e \
	pericolo e dichiari di essere l'unico responsabile dei possibili danni derivanti dall'uso dello stesso.\n
	\nNon si accettano lamentele se il cane miagola o il gatto abbaia durante l'esecuzione del programma.\n
	\nPuò causare sonnolenza. Leggere attentamente il foglietto illustrativo.\n\nHave Fun! \n" 0 0 

}


# La funzione Requisiti controlla che siano installate le dipendenze necessarie ad eseguire
# tutte le sezioni del programma.
# Se i pacchetti mancano vengono installati, altrimenti passa oltre.

Requisiti (){
  
  pkg=dialog
  status="$(dpkg-query -W --showformat='${db:Status-Status}' "$pkg" 2>&1)"
  if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
    clear
    echo "Devo installare "${pkg}" come dipendenza necessaria. Premi INVIO per continuare"
    read
    apt -y install $pkg
  fi

  pkg=deborphan
  status="$(dpkg-query -W --showformat='${db:Status-Status}' "$pkg" 2>&1)"
  if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
    dialog \
      --backtitle "Script Manutenzione Ubuntu" \
      --title "Conferma installazione dipendenze" \
      --msgbox "Devo installare ${pkg} come dipendenza necessaria.\n Premi OK per continuare" 0 0
      apt -y install $pkg
  fi
clear
}

# Questa funzione effettua l'aggiornamento del sistema con i classici comandi

Aggiornamento (){

dialog \
  --backtitle "Script Manutenzione Ubuntu" \
  --title "Conferma" \
  --yesno "Confermi l'esecuzione di questi comandi?\n\n
apt update \n
apt -y dist-upgrade" 0 0

  if [ $? -eq 1 ]; then
        return
  fi

  clear

  data=$(date)
  echo -e "\n\n ****** INIZIO LOG AGGIORNAMENTO SISTEMA ****** ${data} ******\n\n" | \
  sudo -u ${utente} tee -a ${logfile} > /dev/null

  echo -e "\nAPT UPDATE" | sudo -u ${utente} tee -a ${logfile} > /dev/null

  apt-get update | sudo -u ${utente} tee -a ${logfile} 2>&1 | \
  dialog \
    --title "Aggiornamento del sistema" \
    --backtitle "Script Manutenzione Ubuntu" \
    --progressbox 25 90
  cmd1=${PIPESTATUS[0]}

  echo -e "\nAPT -Y DIST-UPGRADE" | sudo -u ${utente} tee -a ${logfile} > /dev/null

  apt-get -y dist-upgrade | sudo -u ${utente} tee -a ${logfile} 2>&1 | \
  dialog \
    --title "Aggiornamento del sistema" \
    --backtitle "Script Manutenzione Ubuntu" \
    --progressbox 25 90 
  cmd2=${PIPESTATUS[0]}

  data=$(date)
  echo -e "\n\n ****** FINE LOG AGGIORNAMENTO SISTEMA ****** ${data} ******\n\n" | \
  sudo -u ${utente} tee -a ${logfile} > /dev/null

  if [ $cmd1 -eq 0 ] && [ $cmd2 -eq 0 ]; then
    dialog \
	    --backtitle "Script Manutenzione Ubuntu" \
	    --title "Successo" \
	    --msgbox "Aggiornamento del sistema eseguito con successo!" 0 0
  else
    dialog \
	    --backtitle "Script Manutenzione Ubuntu" \
	    --title "Errore" \
	    --msgbox "Ops...Qualcosa è andato storto! Controlla il log per i dettagli." 0 0
  fi
clear  
}

# Funzione di eliminazione dei file inutili.
# Da migliorare!

PuliziaSistema () {

cmd=(dialog \
	  --ok-label "Esegui" \
	  --cancel-label "Indietro" \
	  --backtitle "Pulizia del Sistema" \
	  --checklist "Usa la barra spaziatrice per selezionare/deselezionare" 0 0 0)
  
  options=(1 "Pulizia della cache e del cestino" off \
           2 "Pulizia pacchetti orfani e vecchi log" off \
           3 "Riparazione pacchetti bloccati o danneggiati" off)

  choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

  if [ $? -eq 1 ]; then
        clear; return
  fi


  for choice in ${choices}; do 
        case ${choice} in
          1) PuliziaHome ;;
          2) PuliziaPacchetti ;;
          3) RiparazionePacchetti ;;
        esac 
  done

}

PuliziaHome () {
dialog \
  --backtitle "Script Manutenzione Ubuntu" \
  --title "Conferma" \
  --yesno "Confermi l'esecuzione di questi comandi? \n\n rm -rf /home/$utente/.cache/* \n \
rm -rf /home/$utente/.local/share/Trash/*" 0 0

  if [ $? -eq 1 ]; then
        return
  fi

  clear

  data=$(date)
  echo -e "\n\n ****** INIZIO LOG PULIZIA FILE HOME****** ${data} ******\n\n" | \
  sudo -u ${utente} tee -a ${logfile} > /dev/null

  echo -e "\n${date} RM -RF /HOME/${utente}/.cache" | sudo -u ${utente} tee -a ${logfile} > /dev/null

  rm -rf /home/$utente/.cache/* | sudo -u ${utente} tee -a ${logfile} 2>&1 | \
    dialog \
      --title "Pulizia file temporanei" \
      --backtitle "Script Manutenzione Ubuntu" \
      --progressbox 25 90 
  cmd1=${PIPESTATUS[0]}

  #echo -e "\nAPT PURGE '?CONFIG-FILES'" | sudo -u ${utente} tee -a ${logfile} > /dev/null

  #apt-get purge '?config-files' | sudo -u ${utente} tee -a ${logfile} 2>&1 | \
  #  dialog \
  #    --title "Pulizia file temporanei" \
  #    --backtitle "Script Manutenzione Ubuntu" \
  #    --progressbox 25 90 
  #cmd2=${PIPESTATUS[0]}

  echo -e "\n${date} RM -RF ~/.LOCAL/SHARE/TRASH" | sudo -u ${utente} tee -a ${logfile} > /dev/null

  rm -rf /home/${utente}/.local/share/Trash/* | sudo -u ${utente} tee -a ${logfile} 2>&1 | \
    dialog \
      --title "Pulizia file temporanei" \
      --backtitle "Script Manutenzione Ubuntu" \
      --progressbox 25 90 
  cmd2=${PIPESTATUS[0]}

  data=$(date)
  echo -e "\n\n ****** FINE LOG PULIZIA FILE HOME ****** ${data} ******\n\n" | \
  sudo -u ${utente} tee -a ${logfile} > /dev/null

  if [ $cmd1 -eq 0 ] && [ $cmd2 -eq 0 ]; then
	  dialog \
	    --backtitle "Script Manutenzione Ubuntu" \
	    --title "Successo" \
	    --msgbox "Eliminazione file completata" 0 0
  else
	  dialog \
	    --backtitle "Script Manutenzione Ubuntu" \
	    --title "Errore" \
	    --msgbox "Ops...Qualcosa è andato storto! Controlla il log per i dettagli." 0 0
  fi
clear
}

RiparazionePacchetti (){

dialog \
  --stdout \
  --backtitle "Script Manutenzione Ubuntu" \
  --title "Conferma" \
  --yesno "Confermi l'esecuzione di questi comandi? \n\n apt install -f \n dpkg --configure -a \n" 0 0

  if [ $? -eq 1 ]; then
        return
  fi

  clear

  data=$(date)
  echo -e "\n\n ****** INIZIO LOG RIPARAZIONE PACCHETTI ****** ${data} ******\n\n" | \
  sudo -u ${utente} tee -a ${logfile} > /dev/null

  echo -e "\nAPT INSTALL -F" | sudo -u ${utente} tee -a ${logfile} > /dev/null

  apt-get install -f | sudo -u ${utente} tee -a ${logfile} 2>&1 | \
  dialog \
    --title "Riparazione pacchetti" \
    --backtitle "Script Manutenzione Ubuntu" \
    --progressbox 25 90 
  cmd1=${PIPESTATUS[0]}

  echo -e "\nDPKG --CONFIGURE -A" | sudo -u ${utente} tee -a ${logfile} > /dev/null

  dpkg --configure -a | sudo -u ${utente} tee -a ${logfile} 2>&1 | \
  dialog \
    --title "Riparazione pacchetti" \
    --backtitle "Script Manutenzione Ubuntu" \
    --progressbox 25 90 
  cmd2=${PIPESTATUS[0]}

  data=$(date)
  echo -e "\n\n ****** FINE LOG RIPARAZIONE PACCHETTI ****** ${data} ******\n\n" | \
  sudo -u ${utente} tee -a ${logfile} > /dev/null

  if [ $cmd1 -eq 0 ] && [ $cmd2 -eq 0 ]; then
    dialog \
	    --backtitle "Script Manutenzione Ubuntu" \
	    --title "Successo" \
	    --msgbox "Riparazione pacchetti  completata" 0 0
  else
    dialog \
	    --backtitle "Script Manutenzione Ubuntu" \
	    --title "Errore" \
	    --msgbox "Ops...Qualcosa è andato storto! Controlla il log per i dettagli." 0 0
  fi
clear
}



PuliziaPacchetti () {

dialog \
  --backtitle "Script Manutenzione Ubuntu" \
  --title "Conferma" \
  --yesno "Confermi l'esecuzione di questi comandi?\napt clean\napt autoclean\n\
apt autoremove\napt autopurge\ndeborphan | xargs apt -y purge\n\
apt purge '?config-files'\njournalctl --rotate --vacuum-size=500M" 0 0

  if [ $? -eq 1 ]; then
        return
  fi

clear

data=$(date)
echo -e "\n\n ****** INIZIO LOG PULIZIA PACCHETTI OBSOLETI ****** ${data} ******\n\n" | \
sudo -u ${utente} tee -a ${logfile} > /dev/null

echo -e "\nAPT -Y AUTOREMOVE" | sudo -u ${utente} tee -a ${logfile} > /dev/null

apt-get -y autoremove 2>&1 | sudo -u ${utente} tee -a ${logfile}  | \
dialog \
  --title "Pulizia pacchetti obsoleti" \
  --backtitle "Script Manutenzione Ubuntu" \
  --progressbox 25 90 
cmd1=${PIPESTATUS[0]}

echo -e "\nAPT -Y AUTOPURGE" | sudo -u ${utente} tee -a ${logfile} > /dev/null

apt-get -y autopurge 2>&1 | sudo -u ${utente} tee -a ${logfile} | \
dialog \
  --title "Pulizia pacchetti obsoleti" \
  --backtitle "Script Manutenzione Ubuntu" \
  --progressbox 25 90 
cmd2=${PIPESTATUS[0]}

echo -e "\nAPT CLEAN" | sudo -u ${utente} tee -a ${logfile} > /dev/null

apt-get clean 2>&1 | sudo -u ${utente} tee -a ${logfile} | \
dialog \
  --title "Pulizia pacchetti obsoleti" \
  --backtitle "Script Manutenzione Ubuntu" \
  --progressbox 25 90 
cmd3=${PIPESTATUS[0]}

echo -e "\nAPT AUTOCLEAN" | sudo -u ${utente} tee -a ${logfile} > /dev/null

apt-get autoclean 2>&1 | sudo -u ${utente} tee -a ${logfile} | \
dialog \
  --title "Pulizia pacchetti obsoleti" \
  --backtitle "Script Manutenzione Ubuntu" \
  --progressbox 25 90 
cmd4=${PIPESTATUS[0]}

echo -e "\nDEBORPHAN | XARGS APT -Y PURGE" | sudo -u ${utente} tee -a ${logfile} > /dev/null

deborphan | xargs apt-get -y purge 2>&1 | sudo -u ${utente} tee -a ${logfile}  | \
dialog \
  --title "Pulizia pacchetti obsoleti" \
  --backtitle "Script Manutenzione Ubuntu" \
  --progressbox 25 90 
cmd5=${PIPESTATUS[0]}

echo -e "\nAPT PURGE '?CONFIG-FILES'" | sudo -u ${utente} tee -a ${logfile} > /dev/null

apt-get purge '?config-files' 2>&1 | sudo -u ${utente} tee -a ${logfile} | \
dialog \
  --title "Pulizia pacchetti obsoleti" \
  --backtitle "Script Manutenzione Ubuntu" \
  --progressbox 25 90 
cmd6=${PIPESTATUS[0]}

echo -e "JOURNALCTL --ROTATE --VACUUM-SIZE=500M" | sudo -u ${utente} tee -a ${logfile} > /dev/null

journalctl --rotate --vacuum-size=500M 2>&1 | sudo -u ${utente} tee -a ${logfile}  | \
dialog \
  --title "Pulizia pacchetti obsoleti" \
  --backtitle "Script Manutenzione Ubuntu" \
  --progressbox 25 90 
cmd7=${PIPESTATUS[0]}

data=$(date)
echo -e "\n\n ****** FINE LOG PULIZIA PACCHETTI OBSOLETI ****** ${data} ******\n\n" | \
sudo -u ${utente} tee -a ${logfile} > /dev/null

#echo "1: ${cmd1} 2: ${cmd2} 3: ${cmd3} 4: ${cmd4} 5: ${cmd5} 6: ${cmd6} 7: ${cmd7}" && read

if [ $cmd1 -eq 0 ] && [ $cmd2 -eq 0 ] && [ $cmd3 -eq 0 ] && [ $cmd4 -eq 0 ] &&\
 [ $cmd5 -eq 0 ] && [ $cmd6 -eq 0 ] && [ $cmd7 -eq 0 ]; then
    dialog \
	    --backtitle "Script Manutenzione Ubuntu" \
	    --title "Successo" \
	    --msgbox "Pulizia dei pacchetti eseguita con successo!" 0 0
  else
    dialog \
	    --backtitle "Script Manutenzione Ubuntu" \
	    --title "Errore" \
	    --msgbox "Ops...Qualcosa è andato storto! Controlla il log per i dettagli." 0 0
  fi
clear
}

ApriLog () {

if [  -f $1 ]; then
	sudo -H -u ${utente} xdg-open $1 > /dev/null 2>&1
else
	dialog \
	  --title "Errore" \
	  --backtitle "Script Manutenzione Ubuntu" \
	  --msgbox "Il file non esiste. Devi prima eseguire una delle operazioni di manutenzione" 0 0
fi

clear
return

}

FunzioniUtili () {

cmdF=(dialog \
	--ok-label "Esegui" \
	--cancel-label "Indietro" \
	--backtitle "Script Manutenzione Ubuntu" \
	--menu "Funzioni (forse) Utili" 0 0 0)

optionsF=(1 "Salva elenco pacchetti installati"
          2 "Installa pacchetti da elenco salvato"
          3 "Apri file installed-software.log")

choices=$("${cmdF[@]}" "${optionsF[@]}" 2>&1 >/dev/tty)

if [ $? -eq 1 ]; then
      clear; return
fi

for choice in ${choices}; do 
  case ${choice} in
    1) 
	    sudo -H -u ${utente} dpkg --get-selections > /home/${utente}/installed-software.log 
      dialog \
		    --ok-label "Chiudi" \
		    --extra-button \
		    --extra-label "Apri File" \
		    --title "Esportazione completata" \
		    --backtitle "Script Manutenzione Ubuntu" \
		    --msgbox "L'elenco dei pacchetti installati è stato salvato nella tua /home" 0 0

	    if [ $? -eq 0 ]; then
		    clear; return
	    else
		    sudo -H -u ${utente} xdg-open /home/${utente}/installed-software.log > /dev/null 2>&1
	    fi
	  ;;
    2)
      if  [ -e /home/${utente}/installed-software.log ]; then
		    dialog \
          --title "Attenzione!" \
          --backtitle "Script Manutenzione Ubuntu" \
          --yesno "Funzione non testata proseguire ugualmente?" 0 0
		    if [ ! $? -eq 0 ]; then
			    return
		    fi
		    dpkg --set-selections < /home/${utente}/installed-software.log && apt-get dselect-upgrade
	    else
	    	dialog \
 	        --title "Errore!" \
	        --backtitle "Script Manutenzione Ubuntu" \
	        --msgbox "Manca il file installed-software.log" 0 0
	    fi 
	    ;;
    3) ApriLog /home/${utente}/installed-software.log ;;
  esac 
done
clear
}

DiagnosticaAggio () {

filetemp=$(sudo -u ${utente} mktemp)

#ELENCO REPO
echo -e "\n\n[b]cat /etc/apt/sources.list[/b]\n[code]" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

cat /etc/apt/sources.list | sudo -u ${utente} tee -a ${filetemp} | \
  dialog \
    --title "Diagnostica problemi aggiornamenti" \
    --backtitle "Script Manutenzione Ubuntu" \
    --progressbox 25 90

echo -e "[/code]\n\n" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

#EVENTUALI PPA
echo -e "\n\n[b]ls -l /etc/apt/sources.list.d[/b]\n[code]" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

ls -l /etc/apt/sources.list.d | sudo -u ${utente} tee -a ${filetemp} | \
  dialog \
    --title "Diagnostica problemi aggiornamenti" \
    --backtitle "Script Manutenzione Ubuntu" \
    --progressbox 25 90

echo -e "[/code]\n\n" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

#UPDATE
echo -e "\n\n[b]apt-get update[/b]\n[code]" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

apt-get update | sudo -u ${utente} tee -a ${filetemp} | \
  dialog \
    --title "Diagnostica problemi aggiornamenti" \
    --backtitle "Script Manutenzione Ubuntu" \
    --progressbox 25 90

echo -e "[/code]\n\n" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

#UPGRADE
echo -e "\n\n[b]apt-get upgrade[/b]\n[code]" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

apt-get upgrade | sudo -u ${utente} tee -a ${filetemp} | \
  dialog \
    --title "Diagnostica problemi aggiornamenti" \
    --backtitle "Script Manutenzione Ubuntu" \
    --progressbox 25 90

echo -e "[/code]\n\n" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

dialog \
  --backtitle "Script Manutenzione Ubuntu" \
  --title "Info" \
  --msgbox "Copia l'intero contenuto del file ed incollalo sul forum senza modificare nulla." 0 0 

#APRE IL FILE DA POSTARE SUL FORUM

sudo -H -u ${utente} xdg-open ${filetemp} > /dev/null 2>&1

}

DiagnosticaRete () {


filetemp=$(sudo -u ${utente} mktemp)

#LSPCI
echo -e "\n\n[b]lspci -nnk | grep -A3 -i net[/b]\n[code]" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

lspci -nnk | grep -A3 -i net | sudo -u ${utente} tee -a ${filetemp} | \
  dialog \
    --title "Diagnostica problemi aggiornamenti" \
    --backtitle "Script Manutenzione Ubuntu" \
    --progressbox 25 90

echo -e "[/code]\n\n" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

#LSUSB
echo -e "\n\n[b]lsusb[code]" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

lsusb | sudo -u ${utente} tee -a ${filetemp} | \
  dialog \
    --title "Diagnostica problemi aggiornamenti" \
    --backtitle "Script Manutenzione Ubuntu" \
    --progressbox 25 90

echo -e "[/code]\n\n" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

#MOKUTIL
echo -e "\n\n[b]mokutil --sb-state[/b]\n[code]" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

mokutil --sb-state | sudo -u ${utente} tee -a ${filetemp} | \
  dialog \
    --title "Diagnostica problemi aggiornamenti" \
    --backtitle "Script Manutenzione Ubuntu" \
    --progressbox 25 90

echo -e "[/code]\n\n" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

#IWCONFIG
echo -e "\n\n[b]iwconfig[/b]\n[code]" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

iwconfig | sudo -u ${utente} tee -a ${filetemp} | \
  dialog \
    --title "Diagnostica problemi aggiornamenti" \
    --backtitle "Script Manutenzione Ubuntu" \
    --progressbox 25 90

echo -e "[/code]\n\n" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

#NMCLI RADIO
echo -e "\n\n[b]nmcli radio[/b]\n[code]" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

nmcli radio | sudo -u ${utente} tee -a ${filetemp} | \
  dialog \
    --title "Diagnostica problemi aggiornamenti" \
    --backtitle "Script Manutenzione Ubuntu" \
    --progressbox 25 90

echo -e "[/code]\n\n" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

#nmcli connection show
echo -e "\n\n[b]nmcli connection show[/b]\n[code]" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

nmcli connection show | sudo -u ${utente} tee -a ${filetemp} | \
  dialog \
    --title "Diagnostica problemi aggiornamenti" \
    --backtitle "Script Manutenzione Ubuntu" \
    --progressbox 25 90

echo -e "[/code]\n\n" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

#rfkill list
echo -e "\n\n[b]rfkill list[/b]\n[code]" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

rfkill list | sudo -u ${utente} tee -a ${filetemp} | \
  dialog \
    --title "Diagnostica problemi aggiornamenti" \
    --backtitle "Script Manutenzione Ubuntu" \
    --progressbox 25 90

echo -e "[/code]\n\n" | sudo -u ${utente} tee -a ${filetemp} > /dev/null

dialog \
  --backtitle "Script Manutenzione Ubuntu" \
  --title "Info" \
  --msgbox "Copia l'intero contenuto del file ed incollalo sul forum senza modificare nulla." 0 0 

#APRE IL FILE DA POSTARE SUL FORUM
sudo -H -u ${utente} xdg-open ${filetemp} > /dev/null 2>&1
}

MenuForum () {

cmd=(dialog \
	  --ok-label "Esegui" \
	  --cancel-label "Indietro" \
	  --backtitle "Funzioni per forum.ubuntu-it.org" \
	  --menu "Usa la barra spaziatrice per selezionare/deselezionare" 0 0 0)
  
  options=(1 "Diagnostica problemi con gli aggiornamenti" \
           2 "Diagnostica problemi di rete" )

  choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

  if [ $? -eq 1 ]; then
        clear; return
  fi


  for choice in ${choices}; do 
        case ${choice} in
          1) DiagnosticaAggio ;;
          2) DiagnosticaRete ;;
        esac 
  done

}




# Menu principale dello script
Menu () {

  cmd=(dialog \
	  --ok-label "Esegui" \
	  --cancel-label "Esci" \
	  --backtitle "Script Manutenzione Ubuntu" \
	  --menu "Manutenzione del sistema" 0 0 0)
  
  options=(1 "Aggiornamento del sistema"
           2 "Pulizia del sistema"
           3 "Apri log delle operazioni effettuate"
           4 "Funzioni (forse) utili"
           5 "Funzioni per forum.ubuntu-it.org")

  choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

  if [ $? -eq 1 ]; then
        clear; exit
  fi


  for choice in ${choices}; do 
        case ${choice} in
          1) Aggiornamento ;;
          2) PuliziaSistema ;;
	        3) ApriLog ${logfile} ;;
	        4) FunzioniUtili ;;
          5) MenuForum ;;
        esac 
  done
}

CheckConnection (){
  while ! ping -q -c 1 -W 1 google.com >/dev/null 2>&1; do
    echo "Questo script richiede di essere connessi ad Internet per funzionare."
    exit
  done
}

# Main 

# Controlla se lo script è eseguito con privilegi di root

if [ "$EUID" -ne 0 ];
  then echo "Per eseguire lo script devi essere root!"
       echo ""
       echo "Eseguilo così: sudo "$0
exit
fi

# Controlla la connessione
CheckConnection

# Controlla se le dipendenze sono soddisfatte
Requisiti

InizializzaLog

Disclaimer

# Ciclo infinito che richiama la funzione Menu finché l'utente non decide di uscire.
while :; do Menu ; done
exit 0

