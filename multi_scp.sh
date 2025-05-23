#!/bin/bash

# Fonction pour valider le format des IPs
function test_ip_address {
    local ip=$1
    local ip_regex="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    if [[ $ip =~ $ip_regex ]]; then
        return 0
    else
        return 1
    fi
}

# Contrôle des paramètres
if [ "$#" -ne 4 ]; then
    echo -e "\n Utilisation : $0 <SourceFile> <RemoteUser> <RemotePath> <IpListFile>"
    exit 1
fi

SourceFile=$1
RemoteUser=$2
RemotePath=$3
IpListFile=$4

# Contrôle de la présence du fichier à copier
if [ ! -f "$SourceFile" ]; then
    echo -e "\n Fichier source non trouvé : $SourceFile"
    exit 1
fi

# Contrôle de la liste des IPs
if [ ! -f "$IpListFile" ]; then
    echo -e "\n Liste d'IP non trouvée : $IpListFile"
    exit 1
fi

if ! grep -q '[^[:space:]]' "$IpListFile"; then
    echo -e "\n Liste d'IP vide !"
    exit 1
fi

total_ips=$(grep -c '[^[:space:]]' "$IpListFile")
echo -e "Total de $total_ips adresses IP dans la liste"

current=0
successful=0
failed=0

while IFS= read -r ip || [[ -n "$ip" ]]; do
    ip=$(echo "$ip" | xargs) # Retire les espaces en fin de ligne
    current=$((current + 1))
    echo -e "IP en cours de traitement : $ip ($current/$total_ips)\r"

    # Validation des IP
    if ! test_ip_address "$ip"; then
        echo -e "Format d'IP invalide : $ip"
        failed=$((failed + 1))
        continue
    fi

    # Exécution de la commande SCP
    destination="${RemoteUser}@${ip}:${RemotePath}"
    if scp -o StrictHostKeyChecking=no "$SourceFile" "$destination" 2>/dev/null; then
        echo -e "Copié avec succès vers : $ip"
        successful=$((successful + 1))
    else
        echo -e "Echec de la copie vers : $ip"
        failed=$((failed + 1))
    fi
done < "$IpListFile"

# Résumé
echo -e "\n -- Résumé -- "
echo -e "Nombre total d'IPs traitées : $total_ips"
echo -e "Nombre de copies réussies : $successful"
echo -e "Nombre d'échecs : $failed"

# Exemple d'utilisation
echo -e "\nExemple d'utilisation :"
echo -e "$0 './myfile.txt' 'username' '/home/user/' 'ip.lst'\n"
