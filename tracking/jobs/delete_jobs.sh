#!/bin/bash
echo "deleting jobs"
for i in {29757223..29757974..1}
  do 
     qdel $i
 done
