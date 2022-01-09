#!/bin/bash


rm -f go.mod
rm -f go.sum

go mod init test

rm -rf test
# load list of libraries
COUNT=0
while read -r line; do
  # make simple go file for each library
  mkdir -p test/$COUNT
  cp template.go test/$COUNT/main.go

  sed -i -E "s/\/\/\ LIBRARY_GOES_HERE/_ \"$line\"/g" test/$COUNT/main.go
  sed -i -E "s/\ \|\ /\"\n\t_ \"/g" test/$COUNT/main.go
  ((COUNT++))
done < libraries.txt

go mod tidy
go get -v ./...

# compile simple go file:
COUNT=0
while read -r line; do
  echo Count: $COUNT

  #  with go
  go build -o test/$COUNT/go test/$COUNT/main.go
  # with go strip flags
  go build -ldflags "-w -s" -o test/$COUNT/gostripf test/$COUNT/main.go
  # # with go strip
  # go build -o test/$COUNT/gostrip test/$COUNT/main.go
  # strip test/$COUNT/gostrip
  #  with go WASM
  GOOS=js GOARCH=wasm go build -o test/$COUNT/gowasm test/$COUNT/main.go
  #  with tinygo
  tinygo build -o test/$COUNT/tinygo test/$COUNT/main.go
  # #  with tinygo strip
  # tinygo build -o test/$COUNT/tinygostrip test/$COUNT/main.go
  # strip test/$COUNT/tinygostrip
  #  with tinygo WASM
  tinygo build -o test/$COUNT/tinywasm -target=wasm examples/wasm/export
  #  and with go wasm and go - gzipped
  gzip -k test/$COUNT/gowasm
  gzip -k test/$COUNT/go

  ((COUNT++))
done < libraries.txt


# write sizes to csv file
echo -n "" > sizes.csv
echo "package,go,go.gz,gostripf,gowasm,gowasm.gz,tinygo,tinywasm" >> sizes.csv
COUNT=0
while read -r line; do
  # package
  echo -n "$line" | sed -E 's/_ `//; s/\\//; s/\\//; s/`//' >> sizes.csv
  echo -n "," >> sizes.csv
  # go
  ls -lh test/$COUNT | grep -E '\sgo$' | awk '{print $5}' | tr -d '\n' >> sizes.csv
  echo -n "," >> sizes.csv
  # go.gz
  ls -lh test/$COUNT | grep -E '\sgo.gz$' | awk '{print $5}' | tr -d '\n' >> sizes.csv
  echo -n "," >> sizes.csv
  # gostripf
  ls -lh test/$COUNT | grep -E '\sgostripf$' | awk '{print $5}' | tr -d '\n' >> sizes.csv
  echo -n "," >> sizes.csv
  # gowasm
  ls -lh test/$COUNT | grep -E '\sgowasm$' | awk '{print $5}' | tr -d '\n' >> sizes.csv
  echo -n "," >> sizes.csv
  # gowasm.gz
  ls -lh test/$COUNT | grep -E '\sgowasm.gz$' | awk '{print $5}' | tr -d '\n' >> sizes.csv
  echo -n "," >> sizes.csv
  # tinygo
  ls -lh test/$COUNT | grep -E '\stinygo$' | awk '{print $5}' | tr -d '\n' >> sizes.csv
  echo -n "," >> sizes.csv
  # tinywasm
  ls -lh test/$COUNT | grep -E '\stinywasm$' | awk '{print $5}' | tr -d '\n' >> sizes.csv

  echo "" >> sizes.csv
  ((COUNT++))
done < libraries.txt
