#!/bin/bash

# Display the header
clear
cat << "EOF"
 ____ ____ ____ ____ ____ ____ ____
||O |||N |||E |||I |||R |||O |||S ||
||__|||__|||__|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/__\|/__\|/__\|
EOF
echo "https://x.com/0xOneiros"
sleep 4

# Function to return to the main menu
return_to_menu() {
    read -p "Press Enter to return to the main menu..."
    exec "$0"
}

# Display the menu
PS3='Please enter your choice: '
options=("Allora_Node_TestNet" "Chasm_Network" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Allora_Node_TestNet")
            # Download and execute script for option 1
            curl -O https://raw.githubusercontent.com/xONEIROS/Crypto_nodes/main/Allora_Node_TestNet/Allora_Node_TestNet.sh
            chmod +x Allora_Node_TestNet.sh
            ./Allora_Node_TestNet.sh
            return_to_menu
            break
            ;;
        "Chasm_Network")
            # Download and execute script for option 2
            curl -O https://raw.githubusercontent.com/xONEIROS/Crypto_nodes/main/Chasm_Network/Chasm_Network.sh
            chmod +x Chasm_Network.sh
            ./Chasm_Network.sh
            return_to_menu
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
