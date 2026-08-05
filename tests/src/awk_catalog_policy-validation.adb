with Awk_Catalog_Policy.Keys;
with Awk_Catalog_Policy.Locales;
with Awk_Catalog_Policy.Placeholder_Parsing;

package body Awk_Catalog_Policy.Validation is
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
        and then Awk_Catalog_Policy.Keys.Contains
          (Key (Key'First + Prefix'Length .. Key'Last));
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
         for Index in 1 .. Awk_Catalog_Policy.Locales.Count loop
            if Localized_Key_Allowed
              (Key, Awk_Catalog_Policy.Locales.Item (Index) & ".")
            then
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
      Line_Start           : Positive := Text'First;
      Line_No              : Positive := 1;
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
                        elsif not Awk_Catalog_Policy.Placeholder_Parsing.Syntax_Ok (Value) then
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
end Awk_Catalog_Policy.Validation;
