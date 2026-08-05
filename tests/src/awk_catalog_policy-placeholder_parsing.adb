with Ada.Strings.Unbounded;

with Project_Tools.Text;

package body Awk_Catalog_Policy.Placeholder_Parsing is
   package U renames Ada.Strings.Unbounded;

   function Is_Letter (Value : Character) return Boolean is
     ((Value in 'a' .. 'z') or else (Value in 'A' .. 'Z'));

   function Is_Digit (Value : Character) return Boolean is
     (Value in '0' .. '9');

   function Name_Ok (Name : String) return Boolean is
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
   end Name_Ok;

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
                     if Name_Ok (Name)
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

   function Syntax_Ok (Text : String) return Boolean is
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
                 or else not Name_Ok (Text (Index + 1 .. Close - 1))
               then
                  return False;
               end if;
               Index := Close;
            end;
         end if;

         Index := Index + 1;
      end loop;

      return True;
   end Syntax_Ok;
end Awk_Catalog_Policy.Placeholder_Parsing;
