
main points I picked up:

- Full Size + Standby testing is OK
- Security of prod-data is an isse: Test would have to be on anonimzide or "artificial data"
- Upgrade preferably This Year (2020) (consideration: SLA-budget is used?, brexit?)


I detect potentially 3 sub-projects:

- proj1: DB-upgrade
    upgrading the DB itself, excercise on small + large set.
    add: excercxise of fall-back to old-version (e.g. activate old snapshot)
    nb: full-size: ideally same as prod, but Anything >=16CPU, >=64Gmem would be comparable "full-size"
    the main component in full-size is the "realistic data set", e.g. copy of prod or very similar..

    outcomes: 
        - an upgrade-playbook, 
        - including fallback, 
        - estimated througput times.

- proj2: App-testing 
    against an upgraded version (preferablhy large-set + standby-connected)
    determine which applicain stack to use (ACC? )
    note: testing will never be complete, real-world is more complicated then our tests.
    full-size: see proj1
    outcomes: 
        -Testruns from app-stack against upgraded databse
        - [ how to create a test-set, possibly anonimyzed) ]
    

- proj3: Pre-Open-Test
    Prepare a short test-run of upgraded DB (with prod-stack software)
    who:Servicedesk+teamPCS to determine if new version runs acceptable.
    max 30min, then go/nogo.
    After "open to world", there is no going back, only fix-foward.
    Outcomes
        - script to test (max 30min)
        - go/nogo criteria (e.g. when do we decide the upgrade fails..)


-- -- -- 

# op nieuw machine zijn waarshijnlijk volgende commandos nodig:

 yum install epel-release
 yum install ansible git nfs-utils java

 mkdir /share

# voor ansible nodig
 echo "localhost" >> /etc/ansible/hosts
 groupadd -g 10000 ansible
 useradd -u 10000 ansible -g ansible

# pick up ansible (yml) scrips from repository
 git clone https://git.basetide.com/software/ansible.git

#ansible directories directly under ansible home
 ln -s ansible/playbooks
 ln -s ansible/static_files
 ln -s ansible/templates


# copy the oracle install rpms (and db-template?)
# scp _from_vckvmora_ _to_host_

/share/software/oracle-database-preinstall-18c-1.0-1.el7.x86_64.rpm
/share/software/oracle-database-xe-18c-1.0-1.x86_64.rpm

#installing oracle : run the rpms
# double check are ORDSYS, APEX and ORDS included ?



# pick playbook and run

# copy the softwre form vckvmbase to devbox
# permissions, 
x
chmod 777 /share/software 
scp oracle-da*  basetide@34.245.96.228:/share/software 



# XE: pre-install rpms on /share/software : scp those to box.. 

# curl -o oracle-database-preinstall-18c-1.0-1.el6.x86_64.rpm https://yum.oracle.com/repo/OracleLinux/OL6/latest/x86_64/getPackage/oracle-database-preinstall-18c-1.0-1.el6.x86_64.rpm
# yum -y localinstall oracle-database-preinstall-18c-1.0-1.el6.x86_64.rpm

# yum -y localinstall oracle-database-xe-18c-1.0-1.x86_64.rpm

# to install, as root:
# /etc/init.d/oracle-xe-18c configure

# To configure Oracle Database XE, 
# optionally modify the parameters in 
vi /etc/sysconfig/oracle-xe-18c.conf

LISTENER_PORT=1521
EM_EXPRESS_PORT=5500
CHARSET=AL32UTF8
DBFILE_DEST=/data/oradata

# execute db-creation
/etc/init.d/oracle-xe-18c configure

# tnsnames.ora: add xepdb as an entry

# enable autostart

systemctl start oracle-xe-18c
systemctl enable oracle-xe-18c

-- -- 

-- -- -- 
for copy from caliber CALA:

to import complete dump (e.g. from Cal-A)
create relevant directory if needed,
grant read, write on directory oradump to <user> ;

creat parfile:
---[ imp_caliber.par ] ---
userid=piet/***
directory=oradump DUMPFILE=exp_cala_20200623.dmp
LOGFILE=imp_cala_20200623.log
---
impdp parfile=imp_caliber.par



apex install.. 
q : ords before or after ? 

@apexins.sql sysaux sysaux temp /i/

SQL> alter session set container=XEPDB1;
SQL> create tablespace apex;
SQL> @apexins.sql apex apex temp /i/

eerst sqlplus uitzetten

SQL> @apxchpwd.sql
SQL> @apex_rest_config.sql
SQL> alter user apex_listener account unlock;
SQL> alter user apex_public_user account unlock;

meestal Apex50!

java -jar ords.war install advanced
This Oracle REST Data Services instance has not yet been configured.
Please complete the following prompts

Enter the location to store configuration data:/opt/oracle/product/12.2.0/db_1/apex/images/
Enter the name of the database server [localhost]:
Enter the database listen port [1521]:
Enter 1 to specify the database service name, or 2 to specify the database SID [1]:
Enter the database service name:ORCL
Enter 1 if you want to verify/install Oracle REST Data Services schema or 2 to skip this step [1]:
Enter the database password for ORDS_PUBLIC_USER:
Confirm password:
Please login with SYSDBA privileges to verify Oracle REST Data Services schema.

Enter the username with SYSDBA privileges to verify the installation [SYS]:
Enter the database password for SYS:
Confirm password:
Enter the default tablespace for ORDS_METADATA [SYSAUX]:
Enter the temporary tablespace for ORDS_METADATA [TEMP]:
Enter the default tablespace for ORDS_PUBLIC_USER [USERS]:
Enter the temporary tablespace for ORDS_PUBLIC_USER [TEMP]:
Enter 1 if you want to use PL/SQL Gateway or 2 to skip this step.
If using Oracle Application Express or migrating from mod_plsql then you must enter 1 [1]:
Enter the PL/SQL Gateway database user name [APEX_PUBLIC_USER]:
Enter the database password for APEX_PUBLIC_USER:
Confirm password:
Enter 1 to specify passwords for Application Express RESTful Services database users (APEX_LISTENER, APEX_REST_PUBLIC_USER) or 2 to skip this step [1]:
Enter the database password for APEX_LISTENER:
Confirm password:
Enter the database password for APEX_REST_PUBLIC_USER:
Confirm password:
Mar 24, 2020 12:54:05 PM
INFO: Updated configurations: defaults, apex, apex_pu, apex_al, apex_rt
Installing Oracle REST Data Services version 3.0.7.228.03.57
... Log file written to /home/oracle/ords_install_core_2020-03-24_125406_00094.log
... Verified database prerequisites
... Created Oracle REST Data Services schema
... Created Oracle REST Data Services proxy user
... Granted privileges to Oracle REST Data Services
... Created Oracle REST Data Services database objects
... Log file written to /home/oracle/ords_install_datamodel_2020-03-24_125419_00149.log
Completed installation for Oracle REST Data Services version 3.0.7.228.03.57. Elapsed time: 00:00:14.343
Enter 1 if you wish to start in standalone mode or 2 to exit [1]:1
Enter the APEX static resources location:/opt/oracle/product/12.2.0/db_1/apex

Enter 1 if using HTTP or 2 if using HTTPS [1]:1

relevante codes : Ords19  (capital O, version nr)


-- -- -- 
01 July 2020

create tablespaces from cts_yss.sql

import data..

Create user from clean_users.dmp... 
