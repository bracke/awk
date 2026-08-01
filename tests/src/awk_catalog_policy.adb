with Ada.Strings.Unbounded;

package body Awk_Catalog_Policy is
   package U renames Ada.Strings.Unbounded;

   Required : constant array (Positive range <>) of U.Unbounded_String :=
     [U.To_Unbounded_String ("awk.help.title"),
      U.To_Unbounded_String ("awk.help.summary"),
      U.To_Unbounded_String ("awk.help.usage.direct_program"),
      U.To_Unbounded_String ("awk.help.usage.program_files"),
      U.To_Unbounded_String ("awk.help.options.field_separator"),
      U.To_Unbounded_String ("awk.help.options.variable"),
      U.To_Unbounded_String ("awk.help.options.program_file"),
      U.To_Unbounded_String ("awk.help.options.color"),
      U.To_Unbounded_String ("awk.help.options.help"),
      U.To_Unbounded_String ("awk.help.options.version"),
      U.To_Unbounded_String ("awk.help.options.terminator"),
      U.To_Unbounded_String ("awk.help.operands"),
      U.To_Unbounded_String ("awk.help.stdin"),
      U.To_Unbounded_String ("awk.help.exit_statuses"),
      U.To_Unbounded_String ("awk.help.compatibility.heading"),
      U.To_Unbounded_String ("awk.help.compatibility.awklib_limitations"),
      U.To_Unbounded_String ("awk.version.license"),
      U.To_Unbounded_String ("awk.diagnostic.label.info"),
      U.To_Unbounded_String ("awk.diagnostic.label.error"),
      U.To_Unbounded_String ("awk.diagnostic.label.warning"),
      U.To_Unbounded_String ("awk.diagnostic.label.internal_error"),
      U.To_Unbounded_String ("awk.diagnostic.hint"),
      U.To_Unbounded_String ("awk.usage.missing_program"),
      U.To_Unbounded_String ("awk.usage.unknown_option"),
      U.To_Unbounded_String ("awk.usage.missing_option_argument"),
      U.To_Unbounded_String ("awk.usage.invalid_assignment"),
      U.To_Unbounded_String ("awk.usage.invalid_color_mode"),
      U.To_Unbounded_String ("awk.usage.program_file_stdin_unsupported"),
      U.To_Unbounded_String ("awk.program_file.open_failed"),
      U.To_Unbounded_String ("awk.program_file.read_failed"),
      U.To_Unbounded_String ("awk.input_file.open_failed"),
      U.To_Unbounded_String ("awk.input_file.read_failed"),
      U.To_Unbounded_String ("awk.output_file.open_failed"),
      U.To_Unbounded_String ("awk.output_file.write_failed"),
      U.To_Unbounded_String ("awk.standard_input.read_failed"),
      U.To_Unbounded_String ("awk.standard_output.write_failed"),
      U.To_Unbounded_String ("awk.interpreter.parse_failed"),
      U.To_Unbounded_String ("awk.interpreter.runtime_failed"),
      U.To_Unbounded_String ("awk.interpreter.unsupported_operation"),
      U.To_Unbounded_String ("awk.internal.unexpected_exception"),
      U.To_Unbounded_String ("awk.hint.use_help"),
      U.To_Unbounded_String ("awk.hint.option_terminator")];

   function Contains (Text, Pattern : String) return Boolean is
   begin
      if Pattern'Length = 0 then
         return True;
      end if;
      if Text'Length < Pattern'Length then
         return False;
      end if;
      for Index in Text'First .. Text'Last - Pattern'Length + 1 loop
         if Text (Index .. Index + Pattern'Length - 1) = Pattern then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   function Required_Key_Count return Positive is
   begin
      return Required'Length;
   end Required_Key_Count;

   function Required_Key (Index : Positive) return String is
   begin
      return U.To_String (Required (Index));
   end Required_Key;

   function Is_Required_Key (Key : String) return Boolean is
   begin
      for Item of Required loop
         if Key = U.To_String (Item) then
            return True;
         end if;
      end loop;
      return False;
   end Is_Required_Key;

   function Is_Letter (Value : Character) return Boolean is
   begin
      return (Value in 'a' .. 'z') or else (Value in 'A' .. 'Z');
   end Is_Letter;

   function Is_Digit (Value : Character) return Boolean is
   begin
      return Value in '0' .. '9';
   end Is_Digit;

   function Placeholder_Name_Ok (Name : String) return Boolean is
   begin
      if Name'Length = 0 then
         return False;
      end if;
      for Ch of Name loop
         if not (Is_Letter (Ch) or else Is_Digit (Ch) or else Ch = '_') then
            return False;
         end if;
      end loop;
      return True;
   end Placeholder_Name_Ok;

   function Placeholders (Text : String) return String is
      Result : U.Unbounded_String;
      Index  : Positive := Text'First;
   begin
      if Text'Length = 0 then
         return "";
      end if;

      while Index <= Text'Last loop
         if Text (Index) = '{' then
            declare
               Close : Natural := 0;
            begin
               for Scan in Index + 1 .. Text'Last loop
                  if Text (Scan) = '}' then
                     Close := Scan;
                     exit;
                  end if;
               end loop;

               if Close > Index + 1 then
                  declare
                     Name : constant String := Text (Index + 1 .. Close - 1);
                  begin
                     if Placeholder_Name_Ok (Name)
                       and then not Contains (U.To_String (Result), "|" & Name & "|")
                     then
                        U.Append (Result, "|" & Name & "|");
                     end if;
                  end;
                  Index := Close;
               end if;
            end;
         end if;
         Index := Index + 1;
      end loop;
      return U.To_String (Result);
   end Placeholders;

   function Placeholder_Syntax_Ok (Text : String) return Boolean is
      Index : Positive := Text'First;
   begin
      if Text'Length = 0 then
         return True;
      end if;

      while Index <= Text'Last loop
         if Text (Index) = '}' then
            return False;
         elsif Text (Index) = '{' then
            declare
               Close : Natural := 0;
            begin
               for Scan in Index + 1 .. Text'Last loop
                  if Text (Scan) = '}' then
                     Close := Scan;
                     exit;
                  elsif Text (Scan) = '{' then
                     return False;
                  end if;
               end loop;

               if Close = 0
                 or else not Placeholder_Name_Ok (Text (Index + 1 .. Close - 1))
               then
                  return False;
               end if;
               Index := Close;
            end;
         end if;
         Index := Index + 1;
      end loop;
      return True;
   end Placeholder_Syntax_Ok;

   function Equal_Sign (Line : String) return Natural is
   begin
      if Line'Length < 3 then
         return 0;
      end if;

      for Index in Line'First + 1 .. Line'Last - 1 loop
         if Line (Index - 1 .. Index + 1) = " = " then
            return Index;
         end if;
      end loop;
      return 0;
   end Equal_Sign;

   function Localized_Key_Allowed (Key, Prefix : String) return Boolean is
   begin
      return Key'Length > Prefix'Length
        and then Key (Key'First .. Key'First + Prefix'Length - 1) = Prefix
        and then Is_Required_Key (Key (Key'First + Prefix'Length .. Key'Last));
   end Localized_Key_Allowed;

   function Key_Allowed
     (Key              : String;
      Combined_Catalog : Boolean;
      Locale           : String) return Boolean
   is
   begin
      if Combined_Catalog and then Key = "default_locale" then
         return True;
      elsif Combined_Catalog then
         return Localized_Key_Allowed (Key, "en.")
           or else Localized_Key_Allowed (Key, "da.");
      elsif Locale /= "" then
         return Localized_Key_Allowed (Key, Locale & ".");
      else
         return False;
      end if;
   end Key_Allowed;

   function Failure_Message
     (Text             : String;
      Combined_Catalog : Boolean := True;
      Locale           : String := "") return String
   is
      Line_Start : Positive := Text'First;
      Line_No    : Positive := 1;
      Default_Locale_Count : Natural := 0;
   begin
      if Text'Length = 0 then
         return "catalog is empty";
      end if;

      while Line_Start <= Text'Last loop
         declare
            Line_End : Natural := Text'Last;
         begin
            for Scan in Line_Start .. Text'Last loop
               if Text (Scan) = ASCII.LF then
                  Line_End := Scan - 1;
                  exit;
               end if;
            end loop;

            if Line_End >= Line_Start then
               declare
                  Line  : constant String := Text (Line_Start .. Line_End);
                  Equal : constant Natural := Equal_Sign (Line);
               begin
                  if Line'Length /= 0 and then Line (Line'First) /= '#' then
                     if Equal = 0 then
                        return "malformed catalog line" & Line_No'Image;
                     end if;

                     declare
                        Key   : constant String := Line (Line'First .. Equal - 2);
                        Value : constant String := Line (Equal + 2 .. Line'Last);
                     begin
                        if not Key_Allowed (Key, Combined_Catalog, Locale) then
                           return "unknown catalog key: " & Key;
                        elsif Key = "default_locale" then
                           Default_Locale_Count := Default_Locale_Count + 1;
                           if Value /= "en" then
                              return "invalid default locale: " & Value;
                           end if;
                        elsif Value = "" then
                           return "empty catalog value: " & Key;
                        elsif not Placeholder_Syntax_Ok (Value) then
                           return "malformed placeholder in key: " & Key;
                        end if;
                     end;
                  end if;
               end;
            end if;

            Line_Start := Line_End + 2;
            Line_No := Line_No + 1;
         end;
      end loop;

      if Combined_Catalog and then Default_Locale_Count /= 1 then
         return "combined catalog must declare default_locale exactly once";
      end if;

      return "";
   end Failure_Message;
end Awk_Catalog_Policy;
