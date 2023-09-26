function [err, ErrMessage] = WriteBrikHEAD (FileName, Info)
%
%   [err, ErrMessage] = WriteBrikHEAD (FnameHEAD, Info)
%
%Purpose:
%   Create the header file for an AFNI Brik
%
%
%Input Parameters:
%   FnameHEAD the name of the header file
%   Info, a structure detailed in function BrikInfo
%
%Output Parameters:
%   err : 0 No Problem, or warning
%       : 1 Mucho Problems
%   ErrMessage: the warning or error message
%
%
%Key Terms:
%
%More Info :
%
%	see HEAD_Rules function
%
%  This function is meant to be called by WriteBrik function.
%  It will overwrite an existing FnameHEAD so make sure you check
%  for overwrite in the calling function.
%
%  This function deletes any existing IDCODE_STRING
%  It also sets up a new date for the field IDCODE_DATE
%
%  Any fiedls in Info will get written to the .HEAD file.
%  AFNI does not mind adding new fields, but be neat it won't hurt.
%
%  The fields generated by BrikInfo are removed here.
%
% see the files
%   BrikInfo, CheckBrikHEAD, WriteBrik
%
%   NOTE: This function does not perform any checks to determine
%   if the fiedls are appropriate for AFNI. The checks are performed
%   in WriteBrik
%
%   Because these files are not expected to be large, there is no option to
%   replace a certain field. The entire .HEAD is rewritten each time.
%
%   version 2.0
%
%     Author : Ziad Saad
%     Date : Thu Sep 14 16:25:27 PDT 2000
%     LBC/NIMH/ National Institutes of Health, Bethesda Maryland

FUNCTION_VERSION = 'V2.0';

%Define the function name for easy referencing
FuncName = 'WriteBrikHEAD';

%Debug Flag
DBG = 1;
Csep = filesep;

%initailize return variables
err = 1;
ErrMessage = '';

%cleanup fields generated by BrikInfo that are irrelevant to AFNI
if (isfield(Info, 'RootName')), Info = rmfield(Info,'RootName') ; end
if (isfield(Info, 'TypeName')), Info = rmfield(Info,'TypeName') ; end
if (isfield(Info, 'TypeBytes')), Info = rmfield(Info,'TypeBytes') ; end
if (isfield(Info, 'ByteOrder')), Info = rmfield(Info,'ByteOrder') ; end
if (isfield(Info, 'Orientation')), Info = rmfield(Info,'Orientation') ; end
%if (isfield(Info, '')), Info = rmfield(Info,'') ; end


%reset the IDcode, eventually, you'll create one here
if (isfield(Info, 'IDCODE_STRING')),
	Info = rmfield(Info, 'IDCODE_STRING');
end

%setup a new date
Info.IDCODE_DATE = datestr(now,0);

%add the generating code version
Info.GEN_SOURCE = sprintf('WriteBrik matlab library functions %s (please report bugs to saadz@mail.nih.gov)', FUNCTION_VERSION);


fidout = fopen(FileName, 'w');
if (fidout < 0),
	err = 1; ErrMessage = sprintf('Error %s: Could not open %s for writing \n', FuncName, FileName); errordlg(ErrMessage); return;
end

% The tross logger
trlog = getenv('AFNI_HISTDB_SCRIPT');
if (~ isempty(trlog)),
   Info.HISTDB_SCRIPT = trlog;
end

Fld_Allnames  = fieldnames(Info);
Fld_num = size(Fld_Allnames,1);

for (i=1:1:Fld_num),
	Fld_Name = char(Fld_Allnames(i));
	Fld_Val = getfield(Info, Fld_Name);
	Fld_isstrn = 0;
	[err, ErrMessage, Rules] = HEAD_Rules(Fld_Name);
	RulesType = Rules.isNum;
	switch (RulesType),
		case -1, %unknown type, guess
			if (ischar(Fld_Val)),
				%tis a string
				Fld_isstrn = 1;
				Fld_Val = zdeblank(Fld_Val);
				Fld_Type = 'string-attribute';
				Fld_Count = length(Fld_Val)+1;
			elseif (isstruct(Fld_Val)),
				%tis a structure
				err = 1;
				ErrMessage = sprintf('%s: Cannot handle structures', FuncName);
				return;
			elseif (isint(Fld_Val)),
				%tis an integer
				Fld_Type = 'integer-attribute';
				Fld_Count = length(Fld_Val(:));
			else
				%tis a float
				Fld_Type = 'float-attribute';
				Fld_Count = length(Fld_Val(:));
			end
		case 0, %char
			%tis a string
			Fld_isstrn = 1;
			Fld_Val = zdeblank(Fld_Val);
			Fld_Type = 'string-attribute';
			Fld_Count = length(Fld_Val)+1;
		case 1, %int
			%tis an integer
			Fld_Type = 'integer-attribute';
			Fld_Count = length(Fld_Val(:));
		case 2, %float
				%tis a float
				Fld_Type = 'float-attribute';
				Fld_Count = length(Fld_Val(:));
		otherwise,
			err = 1; ErrMessage = sprintf('Error %s: RulesType %d unknown.', FuncName, RulesType); errordlg(ErrMessage); return;
	end			
	%write them out
    if (RulesType >=0 || Fld_Count > 0),
      fprintf(fidout,'\ntype = %s\n', Fld_Type);
	   fprintf(fidout,'name = %s\n', Fld_Name);
	   fprintf(fidout,'count = %g\n', Fld_Count);
       if(Fld_isstrn),
		   %string to write out, do what Bob seems to do
		   stmp = sprintf('''%s~',Fld_Val);
		   fprintf(fidout,'%s\n', stmp);
	   else
		   %write out five values per line, if field is a matrix, reshape it to a
		   %Nx1 vector
		   nsz = size(Fld_Val); npts = nsz(1).*nsz(2);
		   Fld_Val = reshape(Fld_Val, npts, 1);
		   %print out 5 values per line
		   fprintf(fidout, '\t%g\t%g\t%g\t%g\t%g\n', Fld_Val);
		   if (rem(npts,5))
               fprintf(fidout,'\n');
           end
       end
    else
      %Skip those empty fields. Including empty WORSLEY_* attributes
      %was causing scaling factors to be ignored ...
    end
end

fclose (fidout);

err = 0;

return;

