BEGIN {
    list=0
    listNext=0
    liblvl=0
}

match($0, /^( +)[^ ].+ => (.+)$/, ary) {
    #print
    lvl=length(ary[1])
    lib=ary[2]
    
    if (liblvl < lvl) {
        listStack[liblvl] = list
        liblvl = lvl
        list = listNext
    }
    else if (liblvl > lvl) {
        list = listStack[lvl]
        liblvl = lvl
    }
    
    if (index(lib, appdir) == 0) listNext = 1
    else listNext = list
    
    #print "lvl=" lvl, "list=" list, "listNext=" listNext
    
    if ((list > 0) && (index(lib, appdir) > 0)) 
        print lib
    
}

