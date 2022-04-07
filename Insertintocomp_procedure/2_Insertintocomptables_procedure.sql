--Script file for Inserts will be in G3E_DATABASELOCALDIRECTORY directory,with FEATURENAME,FNO part of fileName.
--See that You have access to G3E_DATABASELOCALDIRECTORY
--Tables having null values for atmost 4 side-side columns are only handled(Though insert statements will be generated with missing expression).if table has more than 4 null values in series add criteria below line 80,102.

create or replace 
PROCEDURE
INSERTINOTCOMPTABLES(G3E_FID_SEQ NUMBER,G3E_FNO NUMBER ) AS
  sqlFile UTL_FILE.FILE_TYPE;
  fileName varchar2(400);
  v_table_name      varchar2(30) ;
  v_column_list     varchar2(32000);
  v_insert_list     varchar2(32000);
  v_ref_cur_columns varchar2(32000);
  v_ref_cur_query   varchar2(32000);
  v_ref_cur_query1   varchar2(32000);
  v_ref_cur_output  varchar2(32000);
  v_column_name     varchar2(32000);
  FID               NUMBER(10):=G3E_FID_SEQ;
  FNO               NUMBER(10):=G3E_FNO;
  FEATURE_NAME      VARCHAR2(50);
  refcur            sys_refcursor;  
  GEO_FID           NUMBER;
  GEOMETRY          SDO_GEOMETRY;   
  GEO_ID            NUMBER;  
begin
  Select g3e_username into FEATURE_NAME FROM g3e_feature WHERE G3E_FNO=FNO;
  fileName  := 'INSERT_INTO_COMPONENTTABLES_FOR ' || FEATURE_NAME || FNO || '.sql';
  sqlFile := UTL_FILE.FOPEN ('G3E_DATABASELOCALDIRECTORY', fileName, 'w',5000 );
  for cur in (SELECT a.G3E_TABLE FROM G3E_COMPONENT a,  G3E_FEATURECOMPONENT b WHERE  b.G3E_FNO=FNO and a.g3e_cno = b.g3e_cno ORDER BY b.G3E_INSERTORDINAL)
  loop 
  v_column_list:=NULL;
  v_ref_cur_columns:=NULL;
  for I IN (select column_name, data_type from user_tab_columns where table_name = CUR.G3E_TABLE order by column_id)
  loop
  v_column_list := v_column_list||','||i.column_name;
  if i.data_type = 'NUMBER' then
     v_column_name := i.column_name;
  elsif i.data_type = 'DATE' then
   v_column_name := chr(39)||'to_date('||chr(39)||'||chr(39)'||'||to_char('||i.column_name||','||chr(39)||'dd/mm/yyyy hh:mi:ss'||chr(39)||')||chr(39)||'||chr(39)||', '||chr(39)||'||chr(39)||'||chr(39)||'dd/mm/rrrr hh:mi:ss'||chr(39)||'||chr(39)||'||chr(39)||')'||chr(39);
   elsif i.data_type = 'VARCHAR2' then
        v_column_name := 'chr(39)||'||i.column_name||'||chr(39)';
   elsif i.data_type = 'CHAR' then
        v_column_name := 'chr(39)||'||i.column_name||'||chr(39)';
   elsif i.data_type = 'SDO_GEOMETRY' then
        v_column_name := i.column_name;
   end if;
   if(v_column_name not in ('G3E_GEOMETRY')) then
   v_ref_cur_columns := v_ref_cur_columns||'||'||chr(39)||','||chr(39)||'||'||v_column_name;
	 end if;
  end loop; 
  v_column_list     := ltrim(v_column_list,',');
  v_ref_cur_columns := substr(v_ref_cur_columns,8);
  dbms_output.put_line (v_ref_cur_columns);
  dbms_output.put_line (v_column_list);
  dbms_output.put_line (CUR.G3E_TABLE);
  v_insert_list     := 'INSERT INTO '||CUR.G3E_TABLE||' ('||v_column_list||') VALUES ';
  v_ref_cur_query   := 'SELECT '||v_ref_cur_columns||' FROM '|| CUR.G3E_TABLE || ' WHERE G3E_FID >' || FID || ' AND G3E_FNO=' || FNO;
  v_ref_cur_query1  := 'SELECT G3E_GEOMETRY,G3E_FID,G3E_ID FROM '|| CUR.G3E_TABLE || ' WHERE G3E_FID >' || FID || ' AND G3E_FNO=' || FNO;
  
  
    --Storing data into migrate table  
    if(instr(v_column_list,'G3E_GEOMETRY')>1) then
    open refcur for v_ref_cur_query1;
    loop
    BEGIN
    fetch refcur into GEOMETRY,GEO_FID,GEO_ID;
    exit when refcur%notfound;
    INSERT INTO MIGRATE VALUES (GEO_FID ,GEOMETRY,GEO_ID);
    END;
    end loop;
    END IF;
   
    --inserts statements for table without g3e_geometry column
    if(instr(v_column_list,'G3E_GEOMETRY')=0) then
    open refcur for v_ref_cur_query;
    loop
    BEGIN
    fetch refcur into v_ref_cur_output; 
    exit when refcur%notfound;
    v_ref_cur_output := '('||v_ref_cur_output||');'; 
	v_ref_cur_output := replace(v_ref_cur_output,',,,,,',',null,null,null,null,');
	v_ref_cur_output := replace(v_ref_cur_output,',,,,',',null,null,null,');
	v_ref_cur_output := replace(v_ref_cur_output,',,,',',null,null,');
    v_ref_cur_output := replace(v_ref_cur_output,',,',',null,');
    v_ref_cur_output := replace(v_ref_cur_output,'(,','(null,');
    v_ref_cur_output := replace(v_ref_cur_output,',,)',',null)');
    v_ref_cur_output := replace(v_ref_cur_output,'null,)','null,null)');
    v_ref_cur_output := v_insert_list||v_ref_cur_output; 
    dbms_output.put_line (v_ref_cur_output); 
	UTL_FILE.PUTF (sqlFile , v_ref_cur_output || '\n' ); 
    END;
    end loop;  
    end if;
  
    --inserts statements for table with g3e_geometry column
    if(instr(v_column_list,'G3E_GEOMETRY')>1) then
    open refcur for v_ref_cur_query;
    loop
    BEGIN
    fetch refcur into v_ref_cur_output; 
    exit when refcur%notfound;
    v_ref_cur_output := '('||v_ref_cur_output||',(SELECT G3E_GEOMETRY FROM MIGRATE WHERE G3E_FID=' || REGEXP_SUBSTR(v_ref_cur_output,'[^,]+',1,3) ||' AND G3E_ID = '|| REGEXP_SUBSTR(v_ref_cur_output,'[^,]+',1,1) ||'));'; 
	v_ref_cur_output := replace(v_ref_cur_output,',,,,,',',null,null,null,null,');
	v_ref_cur_output := replace(v_ref_cur_output,',,,,',',null,null,null,');
	v_ref_cur_output := replace(v_ref_cur_output,',,,',',null,null,');
    v_ref_cur_output := replace(v_ref_cur_output,',,',',null,');
    v_ref_cur_output := replace(v_ref_cur_output,'(,','(null,');
    v_ref_cur_output := replace(v_ref_cur_output,',,)',',null)');
    v_ref_cur_output := replace(v_ref_cur_output,'null,)','null,null)');
    v_ref_cur_output := v_insert_list||v_ref_cur_output; 
    dbms_output.put_line (v_ref_cur_output); 
	UTL_FILE.PUTF (sqlFile , v_ref_cur_output || '\n' ); 
    END;
    end loop;  
    end if;
  
end loop;
UTL_FILE.FCLOSE(sqlFile);  
end;