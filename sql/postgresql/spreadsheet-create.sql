-- spreadsheet-create.sql
--
-- @author Benjamin Brink
-- @for OpenACS.org
-- @cvs-id
--

-- we are not going to reference acs_objects directly, so that this can be used
-- separate from acs-core.
CREATE TABLE qss_sheets_object_id_map (
    sheet_id integer,
    object_id integer 
    -- sheet_id constrained to object_id for permissions
);


CREATE SEQUENCE qss_id_seq start 10000;
SELECT nextval ('qss_id_seq');


CREATE TABLE qss_sheets (
    id integer not null primary key,
    template_id integer,
    instance_id integer,
    -- object_id of mounted instance (context_id)

    user_id integer,
    -- user_id of user that created spreadsheet

    flags varchar(12),
    -- to differentiate between data for aggregating and 
    -- complex sheets (with references to multiple sheets for example).

    name varchar(40),
    -- no spaces, single word reference that can be used in urls, filenames etc

    style_ref varchar(300),
    --  might be an absolute ref to a css page, or extended to other style references

    title varchar(80),
    description text,
    orientation varchar(2) default 'RC',
    -- rc = row reference, column reference

    row_count integer,
    -- use value if not null
    cell_count integer,
    -- use value if not null

    trashed varchar(1) default '0',
    popularity integer,
    
    last_calculated timestamptz,
    -- should be the max(qss_cells.last_calculated) for a sheet_id

    last_modified timestamptz,
    -- should be the max(qss_cells.last_modified) for a sheet_id
    last_modified_by integer,
    -- user_id of user that last modified spreadsheet

    status varchar(8)
    -- value will likely be one of
    -- ready      values have been calculated and no active processes working
    -- working    the spreadsheet is in a recalculating process
    -- recalc     values have expired, spreadsheet needs to be recalculated 
);

create index qss_sheets_id_idx on qss_sheets (id);
create index qss_sheets_template_id_idx on qss_sheets (template_id);
create index qss_sheets_instance_id_idx on qss_sheets (instance_id);
create index qss_sheets_user_id_idx on qss_sheets (user_id);
create index qss_sheets_trashed_idx on qss_sheets (trashed);

-- qss_composites is deprecated
-- use a regular sheet and set type/flags to p1 to show it's a 1 row table with column names just like PRETTI p1 type
-- This reduces the need to create a separate API for composites
 -- CREATE TABLE qss_composites (
 --     id integer not null primary key,
 -- 
 --     sheet_id integer not null,
 --     -- should be a value from qss_sheets.sheet_id
 --     -- any external functions referencing only this sheet_id should
 --     -- include copies of function here for caching calculations
 -- 
 --     cell_name varchar(40),
 --     -- usually blank, an alternate reference to RC format
 --     -- unique to a sheet
 -- 
 --     cell_title varchar(80),
 --     -- a label when displaying cell as a single value
 -- 
 -- 
 --     cell_value varchar(1025),
 --     -- returned by function or user input value
 -- 
 --     cell_type varchar(8),
 --     -- type validation, proc and attributes
 -- 
 --     cell_format varchar(80),
 --     -- formatting, css style class
 -- 
 --     cell_proc varchar(1025),
 --     -- contains a function, most commonly an aggregate of associated sheet_id
 --     -- we are calling this a proc because theoretically
 --     -- an admin could define a macro-like proc that returns
 --     -- a value after executing some task, for example, retrieving
 --     -- a value from a url on the net.
 --     -- See ecommerce templating for a similar implementation
 -- 
 --     cell_calc_depth integer not null default '0',
 --     -- this value is to be automatically generated and show this
 --     -- cells order of calculation based on calculation dependencies
 --     -- for example, calc_depth = max (calc_depth of all dependent cells) + 1
 -- 
 --     last_calculated timestamptz,
 --     -- handy for checking when cell value dependencies have changed
 -- 
 --     last_modified timestamptz,
 --     -- data entry (cell value) last changed
 --     last_modified_by integer
 --     -- user that last modified cell
 -- 
 -- ); 



CREATE TABLE qss_cells (
    id integer not null primary key,
    -- It is not efficient to use an sql sequence for so many entries.
    -- Cannot use: row_nbr * col_nbr * ( 0 - ( row_nbr > col_nbr ) )
    -- because inserted cells would cause id collisions
    -- use sheet.cell_count + 1
    -- for partial views or edits
    -- reference the id as well as last_modified in seconds
    -- so that edits reach same cell and changes do not overwrite
    -- other changes made since last_modified 

    sheet_id integer not null,
    --  should be a value from qss_sheets.sheet_id

    cell_row integer not null,
    -- row zero is reserved for column names etc

    cell_column integer not null,

    cell_name varchar(40),
    -- usually blank, an alternate reference to RC format
    -- unique to a sheet
    -- if cell_row is 0 then this is a column_name

    cell_value varchar(1025),
    -- returned by function or user input value
    -- cell_row = 0 is default value for other cells in same column

    cell_type varchar(8),
    -- type validation, proc and attributes
    -- if cell_row = 0, is for entire column

    cell_format varchar(80),
    -- formatting, css style class
    -- cell_row = 0 is default value for other cells in same column
    -- allow some kind of odd/even row formatting change
    --   maybe two styles separated by comma
    --   in row 0 represents first,second alternating
    --   alternating/cycling ends if a format is blank.

    cell_proc varchar(1025),
    -- usually blank or contains a function
    -- cell_row = 0 is default proc for other cells in same column
    -- we are calling this a proc because theoretically
    -- an admin could define a macro-like proc that returns
    -- a value after executing some task, for example, retrieving
    -- a value from a url on the net.
    -- See ecommerce templating for a similar implementation

    cell_calc_depth integer not null default '0',
    -- this value is to be automatically generated and show this
    -- cells order of calculation based on calculation dependencies
    -- for example, calc_depth = max (calc_depth of all dependent cells) + 1

    cell_title varchar(80),
    -- a label when displaying cell as a single value
    -- if cell_row is 0 then this is a column_title

    last_calculated timestamptz,
    -- handy for checking when cell value dependencies have changed

    last_modified timestamptz,
    -- data entry (cell value) last changed

    last_modified_by integer
    -- user that last modified cell
);

create index qss_cells_id_idx on qss_cells (id);
create index qss_cells_sheet_id_idx on qss_cells (sheet_id);
