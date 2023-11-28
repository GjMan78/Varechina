#!/bin/bash

# Autore: GjMan78 per forum.ubuntu.it.org

# Ultimo aggiornamento: 28-11-2023

# Script PARECCHIO work in progress. 

# DA IMPLEMENTARE: 
# - gestione dei log di ogni comando, utli per  debug in caso di errori.
# - eventuale progress bar (dialog --gauge ??)

# DA MIGLIORARE: pulizia file temporanei


# Consenso informato

Disclaimer () {

dialog --backtitle "Dichiarazione di NON responsabilità" \
--title "LEGGI BENE!" \
--msgbox "L'autore declina ogni responsabilità per eventuali danni diretti o indiretti e/o malesseri fisici o psicologici causati dallo script. \n\n
Proseguendo accetti di utilizzare il software fornito a tuo rischio e pericolo e dichiari di essere l'unico responsabile dei possibili danni derivanti dall'uso dello stesso.\n\n 
Non si accettano lamentele se il cane miagola o il gatto abbaia durante l'esecuzione del programma.\n\n
Può causare sonnolenza. Leggere attentamente il foglietto illustrativo.\n\n
Have Fun! \n" 0 0

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

dialog --stdout --yesno "Confermi l'esecuzione di questi comandi?\n\n
apt update \n
apt -y dist-upgrade" 0 0

  resp=$?

  if [ $resp -eq 1 ]; then
        return
  fi

  clear

  apt update
  cmd1=$?

  apt -y dist-upgrade
  cmd2=$?

  if [ $cmd1 -eq 0 ] && [ $cmd2 -eq 0 ]; then
    dialog --msgbox "Aggiornamento del sistema eseguito con successo!" 0 0
  else
    dialog --msgbox "Ops...Qualcosa è andato storto!" 0 0
  fi
}

# Funzione di eliminazione dei file inutili.
# Da migliorare!

PuliziaTemporanei () {
dialog --stdout --yesno "Confermi l'esecuzione di questi comandi? \n\n
rm -rf /home/$USER/.cache/* \n
apt purge '?config-files'" 0 0

  resp=$?

  if [ $resp -eq 1 ]; then
        return
  fi

  clear

  rm -rf /home/$USER/.cache/*
  cmd1=$?

  apt purge '?config-files'
  cmd2=$?

  if [ $cmd1 -eq 0 ] && [ $cmd2 -eq 0 ]; then
	dialog --msgbox "Eliminazione file temporanei completata" 0 0
  else
	dialog --msgbox "Ops...Qualcosa è andato storto!" 0 0
  fi
}

RiparazionePacchetti (){

dialog --stdout --yesno "Confermi l'esecuzione di questi comandi? \n\n
apt install -f \n
dpkg --configure -a \n
" 0 0

  resp=$?

  if [ $resp -eq 1 ]; then
        return
  fi

  clear

  apt install -f
  cmd1=$?

  dpkg --configure -a
  cmd2=$?

  if [ $cmd1 -eq 0 ] && [ $cmd2 -eq 0 ]; then
        dialog --msgbox "Riparazione pacchetti  completata" 0 0
  else
        dialog --msgbox "Ops...Qualcosa è andato storto!" 0 0
  fi
}



PuliziaPacchetti () {

dialog --stdout --yesno "Confermi l'esecuzione di questi comandi?\n
apt clean \n
apt autoclean \n
apt autoremove \n
apt autopurge \n
deborphan | xargs apt -y purge \n
apt purge '?config-files'\n
journalctl --rotate --vacuum-size=500M" 0 0

  resp=$?

  if [ $resp -eq 1 ]; then
        return
  fi

clear

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

if [ $cmd1 -eq 0 ] && [ $cmd2 -eq 0 ] && [ $cmd3 -eq 0 ] && [ $cmd4 -eq 0 ] && [ $cmd5 -eq 0 ] && [ $cmd6 -eq 0 ] && [ $cmd7 -eq 0 ]; then
    dialog --msgbox "Pulizia dei pacchetti eseguita con successo!" 0 0
  else
    dialog --msgbox "Ops...Qualcosa è andato storto!" 0 0
  fi

}

# Menu principale dello script

Menu () {
  resp=''
  choice=''
  choices="$(dialog --ok-label "Esegui" --cancel-label "Esci" --backtitle "Script Manutenzione Ubuntu" --stdout --checklist "Manutenzione del sistema:" 0 0 0 \
    1 "Aggiornamento del sistema" off \
    2 "Eliminazione file temporanei" off \
    3 "Eliminazione pacchetti orfani e vecchi log" off \
    4 "Riparazione pacchetti bloccati o danneggiati" off)"

  resp=$?
  if [ $resp -eq 1 ]; then
        clear; exit
  fi


  for choice in ${choices}; do 
        case ${choice} in
          1) Aggiornamento ;;
          2) PuliziaTemporanei ;;
          3) PuliziaPacchetti ;;
          4) RiparazionePacchetti;;
	  5) clear; exit ;;
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

Disclaimer

# Ciclo infinito che richiama la funzione Menu finché l'utente non decide di uscire.
while :; do Menu ; done
