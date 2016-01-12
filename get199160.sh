#TODO root check

urlsfile=all-urls-uniq.txt
outdir=/outdir
sleepinterval_default=5 #range. random number under this.
sleepinterval=$((RANDOM%sleepinterval_default +1))
#usetor=true
tor_option="--socks5 127.0.0.1:9050"
cookiejarfile=cookiejar
validation_str="something"

while IFS='' read -r line || [[ -n "$line" ]]; do
    #line is url itself
    tail=${line##*/item/}
    newfilename=${outdir}${tail/\//_}
    if ! grep -sq $validation_str $newfilename; then  # 's' option suppresses 'No such file' error
        #do curl
        echo "trying: $line"
        #$usetor && echo -e '  \e[34mwith tor\e[0m'
        curl -# -c $cookiejarfile -L --user-agent 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0'  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H "Accept-Language: ko-KR,ko;q=0.8,en-US;q=0.5,en;q=0.3" $tor_option -s -o $newfilename $line 
        if ! grep -qs $validation_str $newfilename; then # NOT found = FAIL
            rm $cookiejarfile
            echo "removed: $cookiejarfile"
            echo $newfilename
            echo -e '\e[31mFAIL\e[0m' 
            let sleepinterval*=2
            #toggle tor
            #$usetor && usetor=false || usetor=true
            echo -e '\e[31m*\e[0m send tor NEWNYM signal'
            #/etc/tor/torrc
            #tor --hash-password password
            printf "AUTHENTICATE \"password\"\r\nSIGNAL NEWNYM\r\n" | nc 127.0.0.1 9051
        else
            echo -e '\e[32mOK\e[0m' #print OK
            chown usr:grp $newfilename
            chmod 0664 $newfilename
            sleepinterval=$((RANDOM%sleepinterval_default +1))
        fi
        date
        echo "sleep $sleepinterval"
        sleep $sleepinterval
    fi
done < "$urlsfile"

