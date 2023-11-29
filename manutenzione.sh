#!/bin/bash

# Autore: GjMan78 per forum.ubuntu.it.org

# Ultimo aggiornamento: 29-11-2023

# Script PARECCHIO work in progress. 

# DA IMPLEMENTARE: 
# 
# - eventuale progress bar (dialog --gauge ??)

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
     apt -y install $pkg
  fi

  pkg=deborphan
  status="$(dpkg-query -W --showformat='${db:Status-Status}' "$pkg" 2>&1)"
  if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
     apt -y install $pkg
  fi

}

# Questa funzione effettua l'aggiornamento del sistema con i classici comandi

Aggiornamento (){

dialog \
  --stdout \
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
  echo -e "\n\n ****** INIZIO LOG AGGIORNAMENTO SISTEMA ****** ${data} ******\n\n" | sudo -u ${utente} tee -a ${logfile}

  apt update | sudo -u ${utente} tee -a ${logfile}
  cmd1=$?

  apt -y dist-upgrade | sudo -u ${utente} tee -a ${logfile}
  cmd2=$?

  data=$(date)
  echo -e "\n\n ****** FINE LOG AGGIORNAMENTO SISTEMA ****** ${data} ******\n\n" | sudo -u ${utente} tee -a ${logfile}

  if [ $cmd1 -eq 0 ] && [ $cmd2 -eq 0 ]; then
    dialog \
	--backtitle "Script Manutenzione Ubuntu" \
	--title "Successo" \
	--msgbox "Aggiornamento del sistema eseguito con successo!" 0 0
  else
    dialog \
	--backtitle "Script Manutenzione Ubuntu" \
	--title "Errore" \
	--msgbox "Ops...Qualcosa è andato storto!" 0 0
  fi
}

# Funzione di eliminazione dei file inutili.
# Da migliorare!

PuliziaTemporanei () {
dialog \
  --stdout \
  --backtitle "Script Manutenzione Ubuntu" \
  --title "Conferma" \
  --yesno "Confermi l'esecuzione di questi comandi? \n\n rm -rf /home/$USER/.cache/* \n apt purge '?config-files'" 0 0

  if [ $? -eq 1 ]; then
        return
  fi

  clear

  data=$(date)
  echo -e "\n\n ****** INIZIO LOG PULIZIA FILE TEMPORANEI ****** ${data} ******\n\n" | sudo -u ${utente} tee -a ${logfile}

  rm -rf /home/$USER/.cache/* | sudo -u ${utente} tee -a ${logfile}
  cmd1=$?

  apt purge '?config-files' | sudo -u ${utente} tee -a ${logfile}
  cmd2=$?

  data=$(date)
  echo -e "\n\n ****** FINE LOG PULIZIA FILE TEMPORANEI ****** ${data} ******\n\n" | sudo -u ${utente} tee -a ${logfile}

  if [ $cmd1 -eq 0 ] && [ $cmd2 -eq 0 ]; then
	dialog \
	  --backtitle "Script Manutenzione Ubuntu" \
	  --title "Successo" \
	  --msgbox "Eliminazione file temporanei completata" 0 0
  else
	dialog \
	  --backtitle "Script Manutenzione Ubuntu" \
	  --title "Errore" \
	  --msgbox "Ops...Qualcosa è andato storto!" 0 0
  fi
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
  echo -e "\n\n ****** INIZIO LOG RIPARAZIONE PACCHETTI ****** ${data} ******\n\n" | sudo -u ${utente} tee -a ${logfile}

  apt install -f | sudo -u ${utente} tee -a ${logfile}
  cmd1=$?

  dpkg --configure -a | sudo -u ${utente} tee -a ${logfile}
  cmd2=$?

  data=$(date)
  echo -e "\n\n ****** FINE LOG RIPARAZIONE PACCHETTI ****** ${data} ******\n\n" | sudo -u ${utente} tee -a ${logfile}

  if [ $cmd1 -eq 0 ] && [ $cmd2 -eq 0 ]; then
        dialog \
	  --backtitle "Script Manutenzione Ubuntu" \
	  --title "Successo" \
	  --msgbox "Riparazione pacchetti  completata" 0 0
  else
        dialog \
	  --backtitle "Script Manutenzione Ubuntu" \
	  --title "Errore" --msgbox "Ops...Qualcosa è andato storto!" 0 0
  fi
}



PuliziaPacchetti () {

dialog \
  --stdout \
  --backtitle "Script Manutenzione Ubuntu" \ 
  --title "Conferma" \
  --yesno "Confermi l'esecuzione di questi comandi?\n apt clean \n apt autoclean \n apt autoremove \n apt autopurge \n
deborphan | xargs apt -y purge \n
apt purge '?config-files'\n
journalctl --rotate --vacuum-size=500M" 0 0

  if [ $? -eq 1 ]; then
        return
  fi

clear

data=$(date)
echo -e "\n\n ****** INIZIO LOG PULIZIA PACCHETTI OBSOLETI ****** ${data} ******\n\n" | sudo -u ${utente} tee -a ${logfile}

apt -y autoremove
cmd1=$?

apt -y autopurge
cmd2=$?

apt clean
cmd3=$?

apt autoclean
cmd4=$?

deborphan | xargs apt -y purge
cmd5=$?

apt purge '?config-files'
cmd6=$?

journalctl --rotate --vacuum-size=500M
cmd7=$?

data=$(date)
echo -e "\n\n ****** FINE LOG PULIZIA PACCHETTI OBSOLETI ****** ${data} ******\n\n" | sudo -u ${utente} tee -a ${logfile}

if [ $cmd1 -eq 0 ] && [ $cmd2 -eq 0 ] && [ $cmd3 -eq 0 ] && [ $cmd4 -eq 0 ] && [ $cmd5 -eq 0 ] && [ $cmd6 -eq 0 ] && [ $cmd7 -eq 0 ]; then
    dialog \
	--backtitle "Script Manutenzione Ubuntu" \
	--title "Successo" \
	--msgbox "Pulizia dei pacchetti eseguita con successo!" 0 0
  else
    dialog \
	--backtitle "Script Manutenzione Ubuntu" \
	--title "Errore" \
	--msgbox "Ops...Qualcosa è andato storto!" 0 0
  fi

}

ApriLog () {

if [  -f ${logfile} ]; then
	sudo -u ${utente} xdg-open ${logfile} > /dev/null 2>&1
else
	dialog \
	  --title "Errore" \
	  --backtitle "Script Manutenzione Ubuntu" \
	  --msgbox "Il file non esiste. Devi prima eseguire una delle operazioni di manutenzione" 0 0
fi

return

}

FunzioniUtili () {

cmdF=(dialog \
	--ok-label "Esegui" \
	--cancel-label "Indietro" \
	--backtitle "Script Manutenzione Ubuntu" \
	--menu "Funzioni (forse) Utili" 0 0 0)
optionsF=(1 "Salva elenco pacchetti installati"
          2 "Installa pacchetti da elenco salvato")

choices=$("${cmdF[@]}" "${optionsF[@]}" 2>&1 >/dev/tty)

if [ $? -eq 1 ]; then
      clear; return
fi

for choice in ${choices}; do 
        case ${choice} in
          1) 
	    sudo -u ${SUDO_USER} dpkg --get-selections > /home/${SUDO_USER}/installed-software.log 
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
		sudo -u ${SUDO_USER} xdg-open /home/${SUDO_USER}/installed-software.log > /dev/null 2>&1
	    fi
	    ;;
          2)
            if  [ -e /home/${SUDO_USER}/installed-software.log ]; then
		dialog \
                    --title "Attenzione!" \
                    --backtitle "Script Manutenzione Ubuntu" \
                    --yesno "Funzione non testata proseguire ugualmente?" 0 0
		if [ ! $? -eq 0 ]; then
			return
		fi
		dpkg --set-selections < /home/${SUDO_USER}/installed-software.log && apt-get dselect-upgrade
	    else
	    	dialog \
 	      	    --title "Errore!" \
	      	    --backtitle "Script Manutenzione Ubuntu" \
	            --msgbox "Manca il file installed-software.log" 0 0
	    fi 
	    ;;
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
           2 "Eliminazione file temporanei"
           3 "Eliminazione pacchetti orfani e vecchi log"
           4 "Riparazione pacchetti bloccati o danneggiati"
           5 "Apri log delle operazioni effettuate"
           6 "Funzioni (forse) utili")

  choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

  if [ $? -eq 1 ]; then
        clear; exit
  fi


  for choice in ${choices}; do 
        case ${choice} in
          1) Aggiornamento ;;
          2) PuliziaTemporanei ;;
          3) PuliziaPacchetti ;;
          4) RiparazionePacchetti ;;
	  5) ApriLog ;;
	  6) FunzioniUtili :;
        esac 
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

# Controlla se le dipendenze sono soddisfatte
Requisiti

InizializzaLog

Disclaimer

# Ciclo infinito che richiama la funzione Menu finché l'utente non decide di uscire.
while :; do Menu ; done
