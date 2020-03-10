##################
#  LIUM Le Mans  #
##################

# WEB: http://web.univ-lemans.fr/proxy.pac // Not used, firefox set to 'auto-detect'

au_labo=$(ip a | grep "193.52.29.")

if [ ${#au_labo} -gt "0" ]
then
     export http_proxy="http://proxy.univ-lemans.fr:3128"
     export https_proxy="http://proxy.univ-lemans.fr:3128"
     export ftp_proxy="http://proxy.univ-lemans.fr:3128"
     export all_proxy="http://proxy.univ-lemans.fr:3128"
     export HTTP_PROXY="http://proxy.univ-lemans.fr:3128"
     export HTTPS_PROXY="http://proxy.univ-lemans.fr:3128"
     export FTP_PROXY="http://proxy.univ-lemans.fr:3128"
     export ALL_PROXY="http://proxy.univ-lemans.fr:3128"
fi
##################
