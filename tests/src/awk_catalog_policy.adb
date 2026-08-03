with Ada.Strings.Unbounded;
with Awk_Catalog_Policy.Keys;
with Awk_Catalog_Policy.Locales;
with Project_Tools.Text;

package body Awk_Catalog_Policy is
   package U renames Ada.Strings.Unbounded;

   function Required_Key_Count return Positive is
   begin
      return Awk_Catalog_Policy.Keys.Count;
   end Required_Key_Count;

   function Required_Key (Index : Positive) return String is
   begin
      return Awk_Catalog_Policy.Keys.Item (Index);
   end Required_Key;

   function Is_Required_Key (Key : String) return Boolean is
   begin
      return Awk_Catalog_Policy.Keys.Contains (Key);
   end Is_Required_Key;

   function Supported_Locale_Count return Positive is
   begin
      return Awk_Catalog_Policy.Locales.Count;
   end Supported_Locale_Count;

   function Supported_Locale (Index : Positive) return String is
   begin
      return Awk_Catalog_Policy.Locales.Item (Index);
   end Supported_Locale;

   function Is_Supported_Locale (Locale : String) return Boolean is
   begin
      return Awk_Catalog_Policy.Locales.Contains (Locale);
   end Is_Supported_Locale;

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
                       and then not Project_Tools.Text.Contains
                         (U.To_String (Result), "|" & Name & "|")
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
         for Index in 1 .. Supported_Locale_Count loop
            if Localized_Key_Allowed (Key, Supported_Locale (Index) & ".") then
               return True;
            end if;
         end loop;
         return False;
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
