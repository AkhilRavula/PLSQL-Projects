 
 --Dump file will be stored in DATA_PUMP_DIR directory
 --Log file will be stored in G3E_DATABASELOCALDIRECTORY directory
 --Drop Migrate table once dump is done
 declare
      dp_handle       number;
  begin
      dp_handle := dbms_datapump.open(
      operation   => 'EXPORT',
      job_mode    => 'TABLE');

    dbms_datapump.add_file(
      handle    =>  dp_handle,
      filename  => 'MIGRATE.dmp',
      directory => 'DATA_PUMP_DIR');

    dbms_datapump.add_file(
      handle    => dp_handle,
      filename  => 'MIGRATE.log',
      directory => 'G3E_DATABASELOCALDIRECTORY',
      filetype  => DBMS_DATAPUMP.KU$_FILE_TYPE_LOG_FILE);

    dbms_datapump.metadata_filter(
      handle => dp_handle,
      name   => 'NAME_LIST',
      value  => '''MIGRATE''');

    dbms_datapump.start_job(dp_handle);
    dbms_datapump.detach(dp_handle);  
  end;
  /
  
 Drop Table MIGRATE;