# Serhan Ekici's Webpage


## Build

### Dependencies
* sh
* cat
* GNU sed
* [pandoc](https://pandoc.org/)

### Instructions
```
chmod +x gen
./gen
```

### Update Post Using Vim Auto Commands
```
autocmd BufWritePost */webpage/*/*.md,*/webpage/*/*.html,*/webpage/*/conf ! sed -i "s/^date_updated=.*/date_updated=$(date +"\"\%a, \%d \%b \%Y \%H:\%M:\%S \%z\"")/" %:p:h/conf
```
