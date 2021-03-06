#!/bin/bash
################################################################################
##
##  Licensed to the Apache Software Foundation (ASF) under one or more
##  contributor license agreements.  See the NOTICE file distributed with
##  this work for additional information regarding copyright ownership.
##  The ASF licenses this file to You under the Apache License, Version 2.0
##  (the "License"); you may not use this file except in compliance with
##  the License.  You may obtain a copy of the License at
##
##      http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.
##
################################################################################
##
## mini_run.sh - does an ant run on subdirectories.
##

if [ $# -lt 1 ]
    then
    echo "usage: mini_run.sh [FLAGS] <dir>|<file> ... "
    echo ""
    echo "   where <dir> represents a top-level test directory. For example: "
    echo "   components/Menu"
    echo ""
    echo "   or where <file> represents a specific test file. For example: "
    echo "   components/Menu/Properties/Menu_Properties.mxml"
    echo ""
    echo "   You can specify any number of directories or files. (Delimited by spaces)"
    echo "   if you designate -caseName, you should only indicate one file"
    echo ""
    echo "   where [FLAGS] represents optional flags (before other args). Currently supported: "
    echo ""
    echo "   -addAntArg=<-Darg=val> - pass this arg to the ant script. may be repeated."
    echo ""
    echo "   -addArg=<compilerArg> - pass this arg to the compile for this run. may be repeated."
    echo ""
    echo "   -all         - run ALL TESTCASES locally. Report only failures. "
    echo "                  No other args should be used. This takes a long while. "
    echo ""
    echo "   -apollo      - (AIR) compile and run for AIR"
    echo ""
    echo "   -bug=<bugID> - excludes normally, but include testcases associated with <bugID>"
    echo ""
    echo "   -branch=<branch> - fetch excludes for the given branch "
    echo ""
    echo "   -browser     - run in default browser"
    echo ""
    echo "   -caseName=<testcase> - runs <testcase>, if you have also designated a file. "
    echo ""
    echo "   -covtimeout  - add a 30 second additional timeout to run. separate from other timeouts"
    echo ""
    echo "   -createImages - mixin the CreateBitmapReferences, to create baselines image files"
    echo ""
    echo "   -doCheck     - insert tests to database, checking keywords & duplicate testIDs"
    echo ""
    echo "   -debug       - add \"-debug\" to swf compilation "
    echo ""
    echo "   -failures    - run tests that failed last run (mini_run run)"
    echo "                  'Timed out' type failures will not be rerun"
    echo ""
    echo "   -hurricane   - ZIP and SEND files to hurricane server to create baselines."
    echo "                  Use regular file/directory arguments."
    echo "                  Will not run the tests locally. "
    echo ""
    echo "   -imageDiff   - mixin the EnableRemoteImageDiff include, to debug image compares"
    echo ""

    echo "   -keep        - (AIR) keep generated xml files in apollo run"
    echo ""
    echo "   -kw=<keyword> - limit run to test cases with <keyword>"
    echo "                   You can optionally indicate directories or files with -kw flags."
    echo ""
    echo "   -mail=name@address  send mail, if any, to this address only"
    echo ""
    echo "   -myExcludes  - do not fetch excludes from the database; use the ones already present in"
    echo "                  qa/sdk/testsuites/mustella/tests"
    echo ""
    echo "   -nofail      - ignore failures and continue processesing. "
    echo "                  REPORTS NO FAILURES. (useful for bitmap regeneration)"
    echo ""
    echo "   -norun       - don't run anything. If -doCheck, stop after that"
    echo ""
    echo "   -port=<runner port> - specify a port that the Runner will listen on. Ordinarily"
    echo "                         a user won't have to set this. "
    echo "                         because this is passed at compile time as a mixin, the"
    echo "                         only supported ports are 9999 and 10001"
    echo ""
    echo "   -quick       - Non-connectivity option: use existing excludes, skip cleanup"
    echo ""
    echo "   -results=log - get results via flashlog. (server style. Not always possible)"
    echo "   -results=wire- get results over the wire. (the default)"
    echo ""
    echo "   -retest=<bugID> - Run only the testcases associated with <bugID>. No file or dir args needed."
    echo "                  This is a rather narrow sense of retest. Cannot be used detached from db"
    echo ""
    echo "   -rerun       - run cases already compiled. Useful if re-configuring runtimes"
    echo "                  such as comparing standalone to browser, or browser to browser"
    echo ""
    echo "   -skipExclude - run testcases, ignoring any exclusions in the database"
    echo ""
    echo "   -smoke       - run the testcases designated in smoke.properties. must"
    echo "                  designate one or more directory arguments with this flag or use -all"
    echo "              also currently requires the presence of c:/tmp or /tmp  on your machine"
    echo "                  smoke.properties must be in the include text file format". 
    echo "                  designate directories or one or more smoke.properties files"
    echo "                  for example: "
    echo "                  ./mini_run.sh -smoke tests/components runs all of the smoke properties"
    echo "                  found in the subdirectories under components"
    echo "                  see: http://flexteam.macromedia.com/flexwiki/index.php/SDK:QA:mustella#Smoke_Tests"

    echo "   -sniffers    - mixin ALL sniffers (Event,Mouse,Pixel,Object) and playback control"
    echo ""

    echo "   -step_timeout=<seconds>   - ADD <seconds> to every test case step to avoid timeouts. "
    echo "                               useful in the context of running code coverage, etc. when "
    echo "                               things can get rather slow"
    echo ""
    echo "   -tier2       - run the testcases designated in tier2.properties files"
    echo "                  See -smoke for expected behavior" 
    echo " "
    
    echo ""
    echo "   -timeout=<seconds>  - set global test timeout to <seconds> (an int value). "
    echo ""
    echo "   -verbose     - Show more console output"
    echo ""
    echo ""
    echo ""

    exit
fi

if [ "$ANT_HOME" = "" ] 
    then
    echo "ANT_HOME is not set. Please set this variable"
    exit
fi

propfile=properties/mustella_tmp.properties
inherit_propfile=properties/mustella1.properties


hurricane=0
use_wire=true
propfileName=mustella_tmp
newFile=""
cleanFile=""
testName=""
seenFile=""
run_one_file=""
skipcheck=1;
skipexclude=false
imageDiff=0
sniffers=0
createImages=0
timeout=10000
smoke=""
print_passes=true
run_all=0
ant_target=run
browser_run=""
apollo_run=""
exit_on_compile_error=true
extra_arg=""
port=9999
keep=false
find_our_own_files=false

failed_only=0
no_run=0

beliteral=0

check_air=`egrep "use_air" local.properties | egrep -v "^#" | awk -F"=" '{print $2}'`
run_mobile_tests=`egrep "run_mobile_tests" local.properties | egrep -v "^#" | awk -F"=" '{print $2}'`

os=`uname -s | tr '[A-Z]' '[a-z]'`
tmp=`echo $os | egrep "cygwin"`

if [ "$tmp" = "" ]
    then
    tmp=/tmp
else
    tmp=c:/tmp
fi

mkdir $tmp 2>/dev/null



# arg_list=`echo "$*" | awk -f cleanup.awk `


# echo "here is the arg list: $arg_list"

# exit

for i in "$@"
do



        if [ "$i" = "-docheck" ] || [ "$i" = "-doCheck" ]
            then
            skipcheck=0     
            continue
        fi

        if [ "$i" = "-skipexclude" ] || [ "$i" = "-skipExclude" ] || [ "$i" = "-skipexcludes" ] || [ "$i" = "-skipExcludes" ]
            then
            skipexclude=true
            continue
        fi

        if [ "$i" = "-myExcludes" ]
            then
            antArgs="$antArgs -Dexcludes_done=true"
            continue
        fi
            
        if [ "$i" = "-compileOnly" ]
            then
            compileOnly=1
            continue
        fi
            

        if [ "$i" = "-failures" ]
            then
            failed_only=1   

            tmp0=-includes=IncludeFileLocation

            if [ "$extra_arg" = "" ]
                then
                extra_arg="${tmp0}"
            else
                extra_arg="${extra_arg} $tmp0"
            fi
            continue
        fi
            

        if [ "$i" = "-verbose" ]
            then
            beVerbose=true
            antArgs="$antArgs -Ddebug=true"
            continue
        fi
            
        if [ "$i" = "-hurricane" ]
            then
            echo "HURRICANE noted, no local run"
            hurricane=1

        fi

        if [ "$i" = "-nofail" ]
            then
            extra_arg=" ${extra_arg} -includes=NoFail "

        fi

        if [ "$i" = "-imageDiff" ]
            then
            imageDiff=1
            extra_arg=" ${extra_arg} -includes=EnableRemoteImageDiff "
            timeout=1440000
            continue
        fi

        if [ "$i" = "-rerun" ]
            then
            ant_target=rerun
            continue
        fi

        if [ "$i" = "-results=log" ]
            then
            antArgs="$antArgs -Dresult_include=-includes=SendFormattedResultsToLog -Dget_results_from_log=true"
            use_wire=false
            continue
        fi

        if [ "$i" = "-results=wire" ]
            then
            ## with vetting runs, use the log
            if [ "$TEST_REVIEW" != "1" ]
                then
                antArgs="$antArgs -Dresult_include=-includes=SendResultsToRunner -Dget_results_from_log=false"
                use_wire=true
            fi
            continue
        fi

        if [ "$run_mobile_tests" = "true" ]
            then
            use_wire=false
        fi


        if [ "$i" = "-keep" ]
            then
            keep=true
            continue
        fi

        if [ "$i" = "-apollo" ]
            then
            apollo_run=" -Duse_apollo=true"
            check_air=true
            continue
        fi

        if [ "$i" = "-browser" ]
            then
            browser_run=" -Duse_browser=true"
            continue
        fi

        if [ "$i" = "-norun" ]
            then
            no_run=1
            continue
        fi




        if [ "$i" = "-all" ]
            then
            run_all=1
            skipcheck=1     
            timeout=45
            propfileName=mustella1
            exit_on_compile_error=false
            break_early=1
            continue
        fi


        if [ "$i" = "-createImages" ]
            then
            createImages=1
            extra_arg=" ${extra_arg} -includes=CreateBitmapReferences "
            continue
        fi

        if [ "$i" = "-sniffers" ]
            then
            sniffers=1
            extra_arg=" ${extra_arg} -includes=SendResultsToSnifferClient,SendFormattedResultsToLog,PlaybackControl,VerboseMode,EventSnifferRemote,ObjectSnifferRemote,PixelSnifferRemote,MouseSnifferRemote "
            # antArgs="  ${antArgs} -Dexit_include=false"
            antArgs="  ${antArgs} -Dexit_include=-includes=UnitTester"
            timeout=1440000
            continue
        fi


        if [ "$i" = "-smoke" ]
            then
            target=smoke
            smoke=1
            extra_arg=" ${extra_arg} -includes=IncludeFileLocation"
            rm $tmp/IncludeList.txt
            continue
        fi

        if [ "$i" = "-tier2" ]
            then
            target=tier2
            smoke=1
            extra_arg=" ${extra_arg} -includes=IncludeFileLocation"
            rm $tmp/IncludeList.txt
            continue
        fi

        if [ "$i" = "-debug" ]
            then
            extra_arg=" ${extra_arg} -debug"
            
        fi


        if [ "$i" = "-covtimeout" ]
            then
            extra_arg=" ${extra_arg} -includes=CoverageTimeout"
            antArgs="$antArgs -Dcoverage_timeout=30000"
            
        fi

        if [ "$i" = "-quick" ]
            then
            antArgs="$antArgs -Dexcludes_done=true -Dnoclean.set=true"
        fi
            


        startsArgWith=`echo $i | awk '{printf ("%s", substr($1, 0, 4))}'`
        if [ "$startsArgWith" = "-kw=" ]
            then
            echo "we are here: $i"
            tmp0=`echo "$i"  |  sed -e 's/-kw=//' -e 's/ /@/g'`
            # tmp0=`echo "$i"  | awk '{printf ("%s", substr($1, 5))}'`
            echo "we are here: $tmp0"
        
            if [ "$keyword_list" != "" ]
                then
                keyword_list="$keyword_list,$tmp0"
            else
                keyword_list="$tmp0"
            fi
        
            echo $keyword_list

        fi



        startsArgWith=`echo $i | awk '{printf ("%s", substr($1, 0, 5))}'`

        if [ "$startsArgWith" = "-port" ]
            then
            port=`echo $i | awk '{printf ("%s", substr($1, 7))}'`

            ## we can only toggle port. the default is 9999; 
            ## if we want to change it, toggle
            if [ "$port" != "9999" ]
                then
                [ "$extra_arg" = "" ] && extra_arg=" -Duser_args=-includes=RunnerPortAlt" || extra_arg=" ${extra_arg} -includes=RunnerPortAlt" 

            fi

            continue
        fi

        if [ "$startsArgWith" = "-mail" ]
            then
            recip=`echo $i | awk '{printf ("%s", substr($1, 7))}'`

            mailto=" -Drecipients=$recip -Dqa_recipients=$recip -Dalways_recipients=$recip "
            echo "saw -mail, set to: $mailto"

            continue
        fi


        startsArgWith=`echo $i | awk '{printf ("%s", substr($1, 0, 8))}'`

        if [ "$startsArgWith" = "-branch=" ]
            then
            aBranch=`echo $i | awk '{ printf ("%s", substr($1, index($1, "=")+1))}'`

            useBranch=$aBranch
            antArgs="  ${antArgs} -Dbranch_name=${aBranch}"

        fi

        if [ "$startsArgWith" = "-retest=" ]
            then
            theBugID=`echo $i | awk '{ printf ("%s", substr($1, index($1, "=")+1))}'`
            antArgs="  ${antArgs} -Dbug_retry=${theBugID} "
            find_our_own_files=true

            tmp0=-includes=IncludeFileLocation

            if [ "$extra_arg" = "" ]
                then
                extra_arg="${tmp0}"
            else
                extra_arg="${extra_arg} $tmp0"
            fi
            
            # used to continue, but allow users to narrow the run
        fi

        startsArgWith=`echo $i | awk '{printf ("%s", substr($1, 0, 5))}'`
        if [ "$startsArgWith" = "-bug=" ]
            then
            theBugID=`echo $i | awk '{ printf ("%s", substr($1, index($1, "=")+1))}'`
            antArgs="  ${antArgs} -Dbug_retry=${theBugID} "
            continue
        fi


        startsArgWith=`echo $i | awk '{printf ("%s", substr($1, 0, 9))}'`


        if [ "$startsArgWith" = "-caseName" ]
            then
            testName=`echo $i | awk '{printf ("%s", substr($1, 11))}'`
            continue
        fi

        if [ "$startsArgWith" = "-timeout=" ]
            then
            timeout=`echo $i | awk '{printf ("%s", substr($1, 10))}'`
            continue
        fi

        if [ "$startsArgWith" = "-addAntAr" ]
            then
            tmp0=`echo $i | awk '{printf ("%s", substr($1, 12))}'`
            antArgs="$antArgs $tmp0"
            continue
        fi

        if [ "$startsArgWith" = "-step_tim" ]
            then
            tmp0=`echo $i | awk '{printf ("%s", substr($1, 15))}'`
            antArgs="$antArgs -Dstep_timeout=$tmp0"
            continue
        fi

        startsArgWith=`echo $i | awk '{printf ("%s", substr($1, 0, 7))}'`

        if [ "$startsArgWith" = "-addArg" ]
            then
            tmp0=`echo $i | awk '{printf ("%s", substr($1, 9))}'`
            if [ "$extra_arg" = "" ]
                then
                extra_arg="${tmp0}"
            else
                extra_arg="${extra_arg} $tmp0"
            fi
            continue
        fi

        startsWith=`echo $i | awk '{
            x=$1;
            y=substr($1, 0, index($1, "/"));
            if (index(y, "/") > 0)
                printf ( "%s", substr(y, 0, length(y)-1) )
            else
                printf ( "%s", y)}'`


        if [ "$startsWith" = "tests" ]
            then
            ## trim it for Ant. 
            newi=`echo $i | awk '{printf ("%s", substr($1, 7))}'`
            i=$newi
        fi



        ### okay, we dug this up, if it's a -f, we should 
        ### set a -D property for ant run_this_script. 
        ### otherwise, run a whole directory
        ### the other args are the same, however. :(

        tmpx=tests/${i}
        # echo "Looking for $tmpx"

        end=`echo $tmpx | awk -F"." '{print $NF}'`

        if [ ! -f "$tmpx" ] && [ ! -d "$tmpx" ]
            then
            continue
        fi


        ## The case when a baseline or other asset gets checked in makes it difficult to 
        ## know what test to run. Lacking such definition, we run 
        ## all tests in that area.
        if [ "$end" != "mxml" ] && [ ! -d "$tmpx" ]
            then



                        dir=$tmpx
                        while :
                        do

                                ## this fails if the name contains a SWF already.
                                ## we're headed for a directory
                                correctspot=`ls $dir 2>/dev/null | egrep -i "SWFs|swfs"` 

                                # echo "transform with correctspot: $correctspot"
                # 
                # don't get fooled by files with "swf" in them
                # move up until we find a swfs directory, or end up
                # with nowhere to go
                # 
                                if [ "$correctspot" = "" ]  || [ -f "$dir" ] && [ "$dir" != "." ]
                                        then
                    # echo "doing dirname on $dir"
                                        dir=`dirname $dir`
                elif [ "$correctspot" != "" ] || [ "$dir" = "." ]
                    then
                                        tmpx=$dir
                    # get rid of the leading /tests/
                                        i=`echo $dir | awk '{printf ("%s", substr($1, 7))}'`
                                        break
                                fi

                        done
            # echo "result: $i"


        fi


        ## if break_early, we probably don't want to descend into this stuff.
        ##
        

        if [ "$break_early" = "1" ]
            then
            break
        fi


        if [ -f "$tmpx" ] || [ "$smoke" = "1" ]
            then

            # echo "It's a file"

            ### new.
        
            # was:
            dir=`dirname $i`
            dir=`dirname $dir`

            is_mobile_test=`echo $dir | egrep "mobile"`
            has_air=`echo $dir | egrep "apollo"`
            
            if [ "$check_air" = "true" ] && [ "$has_air" = "" ] && [ "$TEST_REVIEW" = "1" ] && [ "$run_mobile_tests" != "true" ]
                then
                echo "AIR vetting run, but directory $dir is not an air test. Will not run it"
                continue
            fi

            if [ "${run_mobile_tests}" != "true" ] && [ "$is_mobile_test" != "" ]
                then
                echo "Not a mobile server, and $dir is a mobile directory.  Will not run it"
                continue
            fi

            if [ "${run_mobile_tests}" = "true" ] && [ "$is_mobile_test" = "" ]
                then
                echo "Mobile server, and $dir is not a mobile directory.  Will not run it."
                continue
            fi
    
            end=`echo $tmpx | awk -F"." '{print $NF}'`

            ## if it's not a .png file, just run the file. If it is a png file, we'll generalize the run
            ## to the directory (not knowing any better)
            if [ "$end" != "png" ]
                then
                        
                ## append to a semicolon delimted list of individual files
                if [ "$run_one_file" != "" ]
                    then
                    tmpz=`basename $i`
                    run_one_file="${run_one_file};${tmpz}"
                else
                    run_one_file=`basename $i`
                fi


            fi

            if [ "$smoke" = "1" ]
                then


                # constrain original directory

                . ./make_smoke.sh $i $target

                sdk_mustella_includes="${sdk_mustella_includes},${tmp_result}"
                sdk_mustella_swfs="${sdk_mustella_swfs},${tmp_dir}" 

            else

                sdk_mustella_includes="${sdk_mustella_includes},${i}"
                sdk_mustella_swfs="${sdk_mustella_swfs},${dir}/**/*.swf" 

            fi

        elif [ -d "$tmpx" ]
            then


            ### Figure out where we might be. 
            ### if this directory has .mxml or .png, we have to move up     
            ### to include the swfs directory. 
            ### anything else, we can assume they gave us the right thing
            
            val=`ls $tmpx/*.mxml 2>/dev/null`
            ret1=$?
            val=`ls $tmpx/*.png 2>/dev/null`
            ret2=$?


            if [ $ret1 != 0 ] && [ $ret2 != 0 ] 
                then
                beliteral=1
            fi


            dir=$tmpx
            adjusted=0
            lastdir=""
            while :
            do
                if [ $beliteral = 1 ]
                    then
                    break
                fi

                correctspot=`ls $dir | egrep -i "SWFs|swfs"`

                echo "at correctspot: $correctspot"
            
                
                if [ "$correctspot" = "" ]
                    then
                    adjusted=1
                    dir=`dirname $dir`
                    [ "$beVerbose" = "true" ] && echo "at adjust dir: $dir"

                    [ "$dir" = "$lastdir" ] && echo "no change, abort" : lastdir=$dir
                    [ "$beVerbose" = "true" ] && echo " last dir: $lastdir"
                    [ "$lastdir" = "" ] && lastdir=$dir && echo "lastdir empty!" 

                else
                    ## clean off the "tests" front
                    tmpx=$dir
                    dir=`echo $dir | awk '{printf ("%s", substr($1, 7))}'`
                    break
                fi

            done

            run_mobile_tests=`egrep "run_mobile_tests" local.properties | egrep -v "^#" | awk -F"=" '{print $2}'`
            is_mobile_test=`echo $dir | egrep "mobile"`
            
            if [ "$check_air" = "true" ] && [ "$has_air" = "" ] && [ "$TEST_REVIEW" = "1" ] && [ "$run_mobile_tests" != "true" ]
                then
                echo "AIR vetting run, but directory $dir is not an air test. Will not run it"
                continue
            fi

            if [ "${run_mobile_tests}" != "true" ] && [ "$is_mobile_test" != "" ]
                then
                echo "Not a mobile server, and $dir is a mobile directory.  Will not run it"
                continue
            fi

            if [ "${run_mobile_tests}" = "true" ] && [ "$is_mobile_test" = "" ]
                then
                echo "Mobile server, and $dir is not a mobile directory.  Will not run it."
                continue
            fi

            if [ $adjusted = 1 ]
                then
        
                ## we need to add a swf directory   
                ## 

                sdk_mustella_includes=${dir}/${correctspot}/**/*.mxml,${sdk_mustella_includes}
                sdk_mustella_swfs=${dir}/${correctspot}/**/*.swf,${sdk_mustella_swfs}
                    

            fi


            ### can we lighten up about the commas? just have a leading comma, big deal

            if [ "$sdk_mustella_includes" != "" ]
                then
                sdk_mustella_includes="${sdk_mustella_includes},${i}/**/*.mxml"
                sdk_mustella_swfs="${sdk_mustella_swfs},${i}/**/*.swf" 
            else
                sdk_mustella_includes="${i}/**/*.mxml"
                sdk_mustella_swfs="${i}/**/*.swf"
            fi

        else
        
            echo "Not found"

        fi



done



### special case: the -smoke and -all case is problematic
if [ "$smoke" = "1" ] && [ "$run_all" = "1" ] 
    then

    ## special case, all and smoke
    propfileName=mustella_tmp   
    print_passes=true

    # make smoke sets tmp_result and tmp_dir
    . ./make_smoke.sh tests $target


    sdk_mustella_includes="${tmp_result}"
    sdk_mustella_swfs="${tmp_dir}"


fi



rm  $propfile  2>/dev/null


if [ "$sdk_mustella_includes" = "" ] && [ "$run_all" = "0" ] && [ "$find_our_own_files" = "false" ] && [ "$failed_only" = "0" ] && [ "$keyword_list" = "" ]
    then
    echo "Nothing was found to include. Will exit"
    exit 1
fi


egrep "sdk.mustella.excludes" $inherit_propfile  | awk -f clobber.awk > $propfile
egrep "apollo_only_excludes" $inherit_propfile  | awk -f clobber.awk >> $propfile



if [ "$find_our_own_files" = "true" ]
    then

    echo "Querying for test files..."
    
    $ANT_HOME/bin/ant -Dbug_retry=$theBugID query_from_bug_id


    ### if there's nothing to run, figure out the includes automatically.
    ### Otherwise, use what we're given
    if [ "$sdk_mustella_includes" = "" ]
        then

        echo " " >> $propfile
        echo " " >> $propfile
        echo "sdk.mustella.swfs=**/*.swf" >> $propfile
        sort -u tmp_mustella_tmp | egrep -v "rows affected" | awk 'BEGIN { printf ("sdk.mustella.includes=")}{printf ("%s,", $NF)}' >> $propfile

        egrep -v "rows affected" ${tmp}/IncludeList.txt.tmp >  ${tmp}/IncludeList.txt
    else

        egrep -v "rows affected" ${tmp}/IncludeList.txt.tmp >  ${tmp}/IncludeList.txt
        echo "sdk.mustella.includes=${sdk_mustella_includes}" >> $propfile
        echo "sdk.mustella.swfs=${sdk_mustella_swfs}" >> $propfile


    fi

elif [ "$failed_only" = "1" ]
    then

    input=failures.txt


    list_of_files=`awk '{if (NF > 1) {print $1}}' $input | sort -u`


    for i in $list_of_files
    do


    derived_swf=`dirname $i`
    derived_swf=`dirname $derived_swf`

    ## create the ant fileset type includes

    tmp0list="$tmp0list,${i}.mxml"


    if [ -d "tests/${derived_swf}/SWFs" ] 
        then
        ## backflips for windows because it will match either:
        f_lower=`ls "tests/${derived_swf}" | egrep "swfs"`
        [ $? = 0 ] &&  swf0list="$swf0list,$derived_swf/swfs/*.swf" || swf0list="$swf0list,$derived_swf/SWFs/*.swf"


    ## on unix(mac) the guess is that it would actually match correctly
    elif [ -d "tests/${derived_swf}/swfs" ] 
        then
        echo "Matched lower"
        swf0list="$swf0list,$derived_swf/swfs/*.swf"


    fi

    done

    ## write properties file
    echo "sdk.mustella.includes=${tmp0list}" >> $propfile
    # echo "sdk.mustella.swfs=**/*.swf" >> $propfile
    echo "sdk.mustella.swfs=$swf0list" >> $propfile


    ## write include file
    outfile=$tmp/IncludeList.txt
    cat $input | sed -e '/^$/d' -e 's/ /$/' > $outfile

elif [ "$keyword_list" != "" ]
    then

    ## this target calls a task that takes the keywords and
    ## creates an include list
    ## and uses any includes to limit the include set


    echo "Feeding mustella includes: $sdk_mustella_includes"

    if [ "$sdk_mustella_includes" = "" ]
        then
        "$ANT_HOME/bin/ant" write_keyword_includes -Dkeyword_list=$keyword_list 
    else
        "$ANT_HOME/bin/ant" write_keyword_includes -Dkeyword_list=$keyword_list -Dsdk.mustella.includes="$sdk_mustella_includes"
    fi

    ret=$?
    echo "Return from ant was: $ret"

        
    if [ "$ret" != "0" ]
        then
        echo "Failure in the keyword run setup. See above errors. Sorry, exiting"
        exit 1;
    fi

    egrep "sdk.mustella.includes" .tmp_file_list >> $propfile
    ## this one is a bit of a hack:
    echo "sdk.mustella.swfs=**/*.swf" >> $propfile



    here=`pwd`

    ## clean that out.

    cleaning=`echo $here | egrep "cygdrive"`

    if [ "$cleaning" != "" ]
        then
        # /cygdrive/c/depot_tmp/depot/flex/qa/sdk/testsuites/mustella
        here=`echo $here | sed -e 's/\/cygdrive\/\([A-Za-z]\)/\1:/'`

    fi


    [ -d classes ] || mkdir classes
    


    extra_arg="${extra_arg} -includes=CurrentIncludeList"
    extra_arg="${extra_arg} -source-path+=${here}/classes";

    ### NEED THE ARGS

else


echo "sdk.mustella.includes=${sdk_mustella_includes}" >> $propfile
echo "sdk.mustella.swfs=${sdk_mustella_swfs}" >> $propfile


    
fi


# echo "sdk.mustella.includes=${sdk_mustella_includes}" 
# echo "sdk.mustella.swfs=${sdk_mustella_swfs}"



## defaults for results fetching. 
# mini run defaults to over-the-wire results fetching (except for vetting (TEST_REVIEW))
if [ "$use_wire" = "true" ]
    then

    rezIsSet=`echo "$antArgs" | egrep "SendResultsToRunner"`

    if [ "$rezIsSet" = "" ] && [ "$TEST_REVIEW" != "1" ]
        then
        antArgs="$antArgs -Dresult_include=-includes=SendResultsToRunner -Dget_results_from_log=false"
    fi


fi
        




# avoid race to know where the build lives (hack)
mkdir build 2>/dev/null
mkdir build/lib 2>/dev/null

## give a run id so it doesn't bother getting one (we don't care).

if [ "$skipcheck" = "0" ] || [ "$TEST_REVIEW" = "1" ] 
    then
    echo "Running testcase checks/inserts...."

    ## test review implies an attended, server run
    if [ "$TEST_REVIEW" = "1" ] 
        then
        echo "As test review"
        echo "$ANT_HOME/bin/ant $mailto -Dfork_compile=true -Dsend_check_email=true -Dfeature=mustella_tmp -Dport=${port} insert_tests"
        "$ANT_HOME/bin/ant" $mailto $antArgs -Dfork_compile=true -Dsend_check_email=true -Dfeature=mustella_tmp -Dport=${port}  insert_tests
        ret=$?
    else
        echo "$ANT_HOME/bin/ant $mailto $antArgs -Dfail_on_testcase_check=true -Dfork_compile=true -Dsend_check_email=false -Ddebug_insert=true -Dfeature=mustella_tmp -Dport=$port insert_tests"
        "$ANT_HOME/bin/ant" $mailto $antArgs -Dfail_on_testcase_check=true -Dfork_compile=true -Dsend_check_email=false -Ddebug_insert=true -Dfeature=mustella_tmp -Dport=${port} insert_tests
        ret=$?
    fi

    ### NEED THE ARGS

    if [ "$ret" != "0" ]
        then
        echo "Bad return from testcase check. exiting."
        exit 1
    fi
else
    echo "Skipping testcase check"

fi


                        
if [ "$TEST_REVIEW" = "1" ] 
    then

    echo "Doing this as a Test Review."
    ant_target=sendResults

    ## let it mail a compile error  
    ## we'll do a comparison, so we need the database

    timeout=45

    echo $ANT_HOME/bin/ant  -Dsave_failures=true $mailto -Dfork_compile=true -Drun_type=mini -Dexit_on_compile_error=false  -Dinsert_results=true -Dfeature=mustella_tmp -Dsubject="$subject"  -Dsocket_mixin=SocketAddress -Dport=${port} -Dauto_exclude=true -Dflex_version=$flex_version  -Dbuild_version=$build_version -Duser_args=${extra_arg} $recipients $qa_recipients $always_recipients $antArgs -Dserver_time="$server_time" -Ddb_time="$db_time" $ant_target -Dplayer.timeout=$timeout $apollo_run

    "$ANT_HOME/bin/ant"  -Dsave_failures=true $mailto -Dfork_compile=true -Drun_type=mini -Dexit_on_compile_error=false  -Dinsert_results=true -Dfeature=mustella_tmp -Dsocket_mixin=SocketAddress -Dport=${port} -Dauto_exclude=true -Dflex_version=$flex_version  -Dbuild_version=$build_version -Duser_args=${extra_arg} $recipients $qa_recipients $always_recipients $antArgs -Dserver_time="$server_time" -Ddb_time="$db_time" $ant_target -Dplayer.timeout=$timeout $apollo_run

elif [ "$hurricane" = "1" ]
    then
    echo "hurricane!"   


    ## the generalized swfs piece: 
    # tmp_hur=`echo ${sdk_mustella_swfs} | sed -e 's/\*\*/swfs/' -e 's/\*.swf/**/'`
    tmp_hur=`echo ${sdk_mustella_swfs} | sed -e 's/\*\*/swfs/' -e 's/\*\*/swfs/' -e 's/\*.swf/**/'`
    tmp_hur2=`echo ${sdk_mustella_swfs} | sed -e 's/\*\*/SWFs/'`


    if [ "$useBranch" = "" ]
        then
        branchArg=""
    else
        branchArg="-Dbranch_name=$useBranch"
    fi
        


    $ANT_HOME/bin/ant zip_materials $branchArg -Dsdk.mustella.includes.send="${sdk_mustella_includes},${tmp_hur},${tmp_hur2}"


else



    if [ "$compileOnly" = "1" ]
        then
        ant_target=compileLite
        exit_on_compile_error=false
    fi

    if [ "$extra_arg" = "" ]
        then
        extra_arg="-includes=SetShowRTE"
    else
        extra_arg="${extra_arg} -includes=SetShowRTE"
    fi


    echo "Doing a regular mini run"


    if [ "$beVerbose" = "true" ]
        then
        echo $ANT_HOME/bin/ant $mailto -Dfork_compile=true  -Dcurrent.run.id=-1 -Dexit_on_compile_error=$exit_on_compile_error -Dinsert_results=false -Dokay_to_exit=true -Dskip_exclude=${skipexclude} -Dfeature=${propfileName} -Dinclude_list=${testName} -Dplayer.timeout=$timeout -Dprint_passes=$print_passes -Dsave_failures=true $browser_run $apollo_run -Duser_args="${extra_arg}" -Dport=${port}  -Dflex_version=$flex_version -Dbuild_version=$build_version $antArgs $ant_target -Dkeep_air=$keep
    fi


    "$ANT_HOME/bin/ant" $mailto -Dfork_compile=true  -Dcurrent.run.id=-1 -Dexit_on_compile_error=$exit_on_compile_error -Dinsert_results=false -Dokay_to_exit=true -Dskip_exclude=${skipexclude} -Dfeature=${propfileName} -Dinclude_list=${testName} -Dplayer.timeout=$timeout -Dprint_passes=$print_passes -Dsave_failures=true $browser_run $apollo_run -Duser_args="${extra_arg}" -Dport=${port}  -Dflex_version=$flex_version -Dbuild_version=$build_version $antArgs -Dserver_time="$server_time" $ant_target -Dkeep_air=$keep 

fi





