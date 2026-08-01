with Ada.Environment_Variables;
package body Awk_CLI.Environment is
   use type U.Unbounded_String;

   function Normalize (Entries : Entry_Vectors.Vector) return Entry_Vectors.Vector is
      Result : Entry_Vectors.Vector;
   begin
      for Item of Entries loop
         if U.Length (Item.Name) > 0 then
            declare
               Found : Natural := 0;
            begin
               if not Result.Is_Empty then
                  for Index in Result.First_Index .. Result.Last_Index loop
                     if Result.Element (Index).Name = Item.Name then
                        Found := Index;
                        exit;
                     end if;
                  end loop;
               end if;

               if Found = 0 then
                  Result.Append (Item);
               else
                  Result.Replace_Element (Found, Item);
               end if;
            end;
         end if;
      end loop;
      return Result;
   end Normalize;

   function Collect return Entry_Vectors.Vector is
      Result : Entry_Vectors.Vector;

      procedure Add (Name, Value : String) is
      begin
         Result.Append
           (Env_Entry'(Name => U.To_Unbounded_String (Name),
                       Value => U.To_Unbounded_String (Value)));
      end Add;
   begin
      Ada.Environment_Variables.Iterate (Add'Access);
      return Normalize (Result);
   exception
      when others =>
         return Normalize (Result);
   end Collect;
end Awk_CLI.Environment;
