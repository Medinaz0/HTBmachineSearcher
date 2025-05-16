#!/bin/bash

# Determine script directory for consistent file access
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"
blackColour="\e[0;30m\033[1m"
whiteColour="\e[1;37m\033[1m"
lightRedColour="\e[1;31m\033[1m"
lightGreenColour="\e[1;32m\033[1m"
lightYellowColour="\e[1;33m\033[1m"
lightBlueColour="\e[1;34m\033[1m"
lightPurpleColour="\e[1;35m\033[1m"
lightTurquoiseColour="\e[1;36m\033[1m"
lightGrayColour="\e[0;37m\033[1m"
darkGrayColour="\e[1;30m\033[1m"

#GlobalVariables
main_url="https://docs.google.com/spreadsheets/d/1dzvaGlT_0xnT-PGO27Z_4prHgA8PHIpErmoWdlUrSoA/export?format=csv&gid=0"
CSV_FILE="$SCRIPT_DIR/s4vi_machines.csv"
CSV_FILE_TEMP="$SCRIPT_DIR/s4vi_machines_temp.csv"

function ctrl_c(){
	echo -e "\n\n${lightPurpleColour}[*]${endColour}${whiteColour} Saliendo...${endColour}"; sleep 1
	tput cnorm ;exit 1
}

trap ctrl_c INT

function homePanel (){
  echo -e "\n${lightBlueColour} [!]${endColour}${whiteColour} Uso:${endColour}"
  echo -e "\t${lightPurpleColour} h)${endColour}${whiteColour} Menu de inicio${endColour}"
  echo -e "\t${lightPurpleColour} m)${endColour}${whiteColour} Listar informacion por nombre de Maquina${endColour}"
  echo -e "\t${lightPurpleColour} d)${endColour}${whiteColour} Listar Maquinas por dificultad${endColour}"
  echo -e "\t${lightPurpleColour} o)${endColour}${whiteColour} Listar Maquinas por S.O ${endColour}"
  echo -e "\t${lightPurpleColour} u)${endColour}${whiteColour} Actualizar archivos${endColour}"
}


function searchMachine () {
  machineName="$1"
  local output
  local found=0  # Bandera para indicar si se encontró la máquina

  # Capturar la salida del comando
  output=$(mlr --icsv filter 'tolower($["Máquina"]) == tolower("'"$machineName"'")' $CSV_FILE 2>/dev/null)

  # Verificar si hay resultados
  if [ -n "$output" ]; then
    echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} Listando Maquina ${endColour}${lightBlueColour} $machineName ${endColour}\n"
    sleep 1
    found=1

    # Procesar y mostrar los resultados con colores
    echo "$output" | mlr --ocsv put '
      $["Máquina"] = "\033[32m" . $["Máquina"] . "\033[0m";
      $["Dirección IP"] = "\033[31m" . $["Dirección IP"] . "\033[0m";
      $["Sistema Operativo"] = "\033[36m" . $["Sistema Operativo"] . "\033[0m";
      $Dificultad = "\033[33m" . $Dificultad . "\033[0m";
      $["Técnicas Vistas"] = "\033[31m" . $["Técnicas Vistas"] . "\033[0m";
      $Like = "\033[35m" . $Like . "\033[0m";
      $Resuelta = "\033[34m" . $Resuelta . "\033[0m"
    ' | sed \
      -e '1s/^\(Máquina\)/\x1b[32m\1\x1b[0m/' \
      -e '1s/\(Dirección IP\)/\x1b[31m\1\x1b[0m/' \
      -e '1s/\(Sistema Operativo\)/\x1b[36m\1\x1b[0m/' \
      -e '1s/\(Dificultad\)/\x1b[33m\1\x1b[0m/' \
      -e '1s/\(Técnicas Vistas\)/\x1b[31m\1\x1b[0m/' \
      -e '1s/\(Like\)/\x1b[35m\1\x1b[0m/' \
      -e '1s/\(Resuelta\)/\x1b[34m\1\x1b[0m/' \
      -e '2i\\'  # 👈 Inserta salto de línea después del encabezado
  fi

  # Mostrar mensaje de error si no se encontró
  if [ "$found" -eq 0 ]; then
    echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} No existe${endColour}${redColour} $machineName${endColour}"
    exit 1
  fi
}

function searchDifficulty () {
  tput civis
  difficulty="$1"
  echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} Listando Maquinas de dificultad${endColour}${lightBlueColour} $difficulty ${endColour}\n"
  sleep 1

  normalized_diff=$(echo "$difficulty" | iconv -f utf8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' 2>/dev/null)
  
  if [ -n "$normalized_diff" ]; then
    # Capturar la salida de mlr para verificar si hay resultados
    output=$(mlr --icsv --opprint --ifs ',' filter '
      tolower(gsub(gsub($Dificultad, "[áàäâã]", "a"), "[éèëê]", "e")) == "'"$normalized_diff"'" ||
      tolower(gsub(gsub(gsub($Dificultad, "[íìïî]", "i"), "[óòöôõ]", "o"), "[úùüû]", "u")) == "'"$normalized_diff"'" ||
      tolower($Dificultad) == "'"$normalized_diff"'"' \
    then cut -f Dificultad,Máquina $CSV_FILE)
    
    if [ -n "$output" ]; then
      # Aplicar formato si hay resultados
      echo "$output" | sed \
        -e "1s/Máquina/\x1b[1;32mMáquina\x1b[0m/" \
        -e "1s/Dificultad/\x1b[1;33mDificultad\x1b[0m/" \
        -e "s/Fácil/\x1b[1;32mFácil\x1b[0m/g" \
        -e "s/Facil/\x1b[1;32mFacil\x1b[0m/gI" \
        -e "s/Media/\x1b[1;33mMedia\x1b[0m/gI" \
        -e "s/Medio/\x1b[1;33mMedio\x1b[0m/gI" \
        -e "s/Difícil/\x1b[1;31mDifícil\x1b[0m/gI" \
        -e "s/Dificil/\x1b[1;31mDificil\x1b[0m/gI" \
        -e "s/Insane/\x1b[1;35mInsane\x1b[0m/gI"
    else
      echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} Dificultad inválida${endColour}${redColour} $difficulty${endColour}"
    fi
  else
    echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} Dificultad inválida${endColour}${redColour} $difficulty${endColour}"
  fi
  
  tput cnorm
}

function searchOS () {
  tput civis
  os="$1"
  echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} Listando máquinas con sistema operativo${endColour}${lightBlueColour} $os ${endColour}"
  sleep 1

  # Normalizar entrada (quitar tildes, convertir a minúsculas)
  normalized_os=$(echo "$os" | iconv -f utf8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' 2>/dev/null)

  if [ -n "$normalized_os" ]; then
    output=$(mlr --icsv --opprint --ifs ',' put '
      $sist_os_norm = tolower(gsub(gsub(gsub(gsub(gsub($["Sistema Operativo"], "[áàäâã]", "a"), "[éèëê]", "e"), "[íìïî]", "i"), "[óòöôõ]", "o"), "[úùüû]", "u"))
    ' then filter '$sist_os_norm == "'"$normalized_os"'"' \
    then cut -f "Sistema Operativo",Máquina,Dificultad,"Dirección IP" $CSV_FILE 2>/dev/null)

    if [ -n "$output" ]; then
      echo "$output" | sed \
        -e "1s/Sistema Operativo/\x1b[1;36mSistema Operativo\x1b[0m/" \
        -e "1s/Máquina/\x1b[1;32mMáquina\x1b[0m/" \
        -e "1s/Dificultad/\x1b[1;33mDificultad\x1b[0m/" \
        -e "1s/Dirección IP/\x1b[1;34mDirección IP\x1b[0m/" \
        -e "s/Fácil/\x1b[1;32mFácil\x1b[0m/gI" \
        -e "s/Facil/\x1b[1;32mFacil\x1b[0m/gI" \
        -e "s/Media/\x1b[1;33mMedia\x1b[0m/gI" \
        -e "s/Medio/\x1b[1;33mMedio\x1b[0m/gI" \
        -e "s/Difícil/\x1b[1;31mDifícil\x1b[0m/gI" \
        -e "s/Dificil/\x1b[1;31mDificil\x1b[0m/gI" \
        -e "s/Insane/\x1b[1;35mInsane\x1b[0m/gI" \
        -E -e 's/([0-9]{1,3}(\.[0-9]{1,3}){3})/\x1b[1;34m\1\x1b[0m/g'
      echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} Sistemas encontrados para${endColour}${redColour} $os ${endColour}"
    else
      echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} No existen máquinas con sistema${endColour}${redColour} $os ${endColour}"
    fi
  else
    echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} Sistema operativo inválido${endColour}${redColour} $os ${endColour}"
  fi

  tput cnorm
}

function searchByOSAndDifficulty () {
  tput civis
  os="$1"
  difficulty="$2"

  echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} Listando máquinas con sistema operativo${endColour}${lightBlueColour} $os${endColour} ${whiteColour}y dificultad${endColour}${yellowColour} $difficulty ${endColour}"
  sleep 1

  # Normalizar entradas
  normalized_os=$(echo "$os" | iconv -f utf8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]')
  normalized_difficulty=$(echo "$difficulty" | iconv -f utf8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]')

  if [ -n "$normalized_os" ] && [ -n "$normalized_difficulty" ]; then
    output=$(mlr --icsv --opprint --ifs ',' put '
      $os_norm = tolower(gsub(gsub(gsub(gsub(gsub($["Sistema Operativo"], "[áàäâã]", "a"), "[éèëê]", "e"), "[íìïî]", "i"), "[óòöôõ]", "o"), "[úùüû]", "u"));
      $dif_norm = tolower(gsub(gsub(gsub(gsub(gsub($Dificultad, "[áàäâã]", "a"), "[éèëê]", "e"), "[íìïî]", "i"), "[óòöôõ]", "o"), "[úùüû]", "u"))
    ' then filter '$os_norm == "'"$normalized_os"'" && $dif_norm == "'"$normalized_difficulty"'"' \
    then cut -f "Sistema Operativo",Máquina,Dificultad,"Dirección IP" $CSV_FILE 2>/dev/null)

    if [ -n "$output" ]; then
      echo "$output" | sed \
        -e "1s/Sistema Operativo/\x1b[1;36mSistema Operativo\x1b[0m/" \
        -e "1s/Máquina/\x1b[1;32mMáquina\x1b[0m/" \
        -e "1s/Dificultad/\x1b[1;33mDificultad\x1b[0m/" \
        -e "1s/Dirección IP/\x1b[1;34mDirección IP\x1b[0m/" \
        -e "s/Fácil/\x1b[1;32mFácil\x1b[0m/gI" \
        -e "s/Facil/\x1b[1;32mFacil\x1b[0m/gI" \
        -e "s/Media/\x1b[1;33mMedia\x1b[0m/gI" \
        -e "s/Medio/\x1b[1;33mMedio\x1b[0m/gI" \
        -e "s/Difícil/\x1b[1;31mDifícil\x1b[0m/gI" \
        -e "s/Dificil/\x1b[1;31mDificil\x1b[0m/gI" \
        -e "s/Insane/\x1b[1;35mInsane\x1b[0m/gI" \
        -E -e 's/([0-9]{1,3}(\.[0-9]{1,3}){3})/\x1b[1;34m\1\x1b[0m/g'

      echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} Coincidencias encontradas para${endColour}${lightBlueColour} $os${endColour}${whiteColour} con dificultad${endColour}${yellowColour} $difficulty ${endColour}"
    else
      echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} No se encontraron máquinas con esos filtros.${endColour}"
    fi
  else
    echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} Parámetros inválidos.${endColour}"
  fi

  tput cnorm
}

function searchTechnique () {
  tput civis
  raw_input="$1"

  echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} Buscando máquinas por técnicas vistas: ${endColour}${lightBlueColour}$raw_input${endColour}"
  sleep 1

  # Reemplazar comas por espacio, y convertir a array
  IFS=' ' read -ra technique_array <<< "$(echo "$raw_input" | tr ',' ' ')"

  # Construir condiciones del filtro
  condition=""
  for tech in "${technique_array[@]}"; do
    normalized=$(echo "$tech" | iconv -f utf8 -t ascii//TRANSLIT | tr '[:upper:]' '[:lower:]' | xargs)
    condition+="tolower($\"Técnicas Vistas\") =~ \"$normalized\" || "
  done

  # Quitar último " || "
  condition="${condition::-4}"

  # Ejecutar búsqueda
  output=$(mlr --icsv --opprint --ifs ',' filter "$condition" then cut -f "Técnicas Vistas",Máquina,Dificultad,"Dirección IP","Sistema Operativo" s4vi_machines.csv 2>/dev/null)

  if [ -n "$output" ]; then
    echo ""
    echo "$output" | sed \
      -e "1s/Técnicas Vistas/\x1b[1;36mTécnicas Vistas\x1b[0m/" \
      -e "1s/Máquina/\x1b[1;32mMáquina\x1b[0m/" \
      -e "1s/Dificultad/\x1b[1;33mDificultad\x1b[0m/" \
      -e "1s/Dirección IP/\x1b[1;34mDirección IP\x1b[0m/" \
      -e "1s/Sistema Operativo/\x1b[1;36mSistema Operativo\x1b[0m/" \
      -e "s/Fácil/\x1b[1;32mFácil\x1b[0m/gI" \
      -e "s/Media/\x1b[1;33mMedia\x1b[0m/gI" \
      -e "s/Difícil/\x1b[1;31mDifícil\x1b[0m/gI" \
      -e "s/Insane/\x1b[1;35mInsane\x1b[0m/gI"
    echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} Técnicas encontradas: ${endColour}${redColour}$raw_input${endColour}"
  else
    echo -e "\n${lightBlueColour}[!]${endColour}${whiteColour} No se encontraron máquinas para técnicas: ${endColour}${redColour}$raw_input${endColour}"
  fi

  tput cnorm
}



function updateDb (){
  if [ ! -f $CSV_FILE ]; then
    tput civis
    echo -e "\n${lightBlueColour} [!]${endColour}${whiteColour} Descargando archivos importantes${endColour}"
    curl -s -L -o $CSV_FILE $main_url
    tail -n +4 $CSV_FILE | sponge $CSV_FILE
    mlr --icsv --ocsv put '
    $["Técnicas Vistas"] = gsub($["Técnicas Vistas"], "\n", " ");
    $Like = gsub($Like, "\n", " ");
    ' $CSV_FILE | sponge $CSV_FILE 
    sleep 2
    echo -e "\n${lightBlueColour} [!]${endColour}${whiteColour} Todos los archivos descargados${endColour}"
    tput cnorm
  else
  tput civis
  echo -e "\n${lightBlueColour} [!]${endColour}${whiteColour} Comprobando si hay actualizaciones pendientes...${endColour}"
  sleep 1
  curl -s -L -o $CSV_FILE_TEMP $main_url
  tail -n +4 $CSV_FILE_TEMP | sponge $CSV_FILE_TEMP
  mlr --icsv --ocsv put '
    $["Técnicas Vistas"] = gsub($["Técnicas Vistas"], "\n", " ");
    $Like = gsub($Like, "\n", " ");
    ' $CSV_FILE_TEMP | sponge $CSV_FILE_TEMP
  md5_temp_machines=$(md5sum $CSV_FILE_TEMP | awk '{print $1}')
  md5_machines=$(md5sum $CSV_FILE | awk '{print $1}')
    if [ "$md5_temp_machines" == "$md5_machines"  ]; then
      echo -e "\n${lightBlueColour} [!]${endColour}${whiteColour} No hay actualizaciones${endColour}"
      rm $CSV_FILE_TEMP
    else  
      echo -e "\n${lightBlueColour} [!]${endColour}${whiteColour} Se han encontrado actualizaciones${endColour}"
      rm $CSV_FILE && mv $CSV_FILE_TEMP $CSV_FILE
      sleep 2 
      echo -e "\n${lightBlueColour} [!]${endColour}${whiteColour} Se han actualizado los datos${endColour}"
    fi
    tput cnorm
  fi
}

declare -i parameter_counter=0 

#hintsParameters
declare -i hint_difficulty=0
declare -i hint_os=0


while getopts "m:d:o:uh" arg;do
  case $arg in 
  m) machineName="$OPTARG" parameter_counter+=1;;
  o) os="$OPTARG";hint_os=1; parameter_counter+=4;;
  d) difficulty="$OPTARG";hint_difficulty=1; parameter_counter+=3;;
  u) parameter_counter+=2;;
  h) ;;
  esac
done

if [ $parameter_counter -eq 1 ]; then
  searchMachine $machineName
elif [ $parameter_counter -eq 2 ]; then
  updateDb
elif [ $parameter_counter -eq 3 ]; then
  searchDifficulty $difficulty
elif [ $parameter_counter -eq 4 ];then
  searchOS $os 
elif [ $hint_difficulty -eq 1 ] && [ $hint_os -eq 1 ]; then
  searchByOSAndDifficulty $os $difficulty 
else
  homePanel
fi


