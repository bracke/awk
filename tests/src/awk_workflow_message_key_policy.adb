with Ada.Strings.Unbounded;

with Awk_Catalog_Policy;
with Project_Tools.Files;
with Project_Tools.Release_Checks;
with Project_Tools.Test_Fixtures;
with Project_Tools.Text;

package body Awk_Workflow_Message_Key_Policy is
   package Files renames Project_Tools.Files;
   package Fixtures renames Project_Tools.Test_Fixtures;
   package U renames Ada.Strings.Unbounded;

   function First_Unknown_Production_Key_Literal
     (Root : String := "../src") return String
   is
      Prefix : constant String := """awk.";

      function First_In_File (Name : String) return String is
         Source_Text : constant String := Fixtures.Read_Text_File (Name);
         Start       : Natural := Project_Tools.Text.Index (Source_Text, Prefix);
      begin
         while Start /= 0 loop
            declare
               Key_First : constant Positive := Start + 1;
               Key_Last  : Natural := 0;
            begin
               for Scan in Key_First .. Source_Text'Last loop
                  if Source_Text (Scan) = '"' then
                     Key_Last := Scan - 1;
                     exit;
                  end if;
               end loop;

               if Key_Last >= Key_First then
                  declare
                     Key : constant String := Source_Text (Key_First .. Key_Last);
                  begin
                     if not Awk_Catalog_Policy.Is_Required_Key (Key) then
                        return Name & ": " & Key;
                     end if;
                  end;
               end if;

               exit when Start = Source_Text'Last;
               Start := Project_Tools.Text.Index_From (Source_Text, Prefix, Start + 1);
            end;
         end loop;

         return "";
      end First_In_File;

      function First_In_Tree (Name_Pattern : String) return String is
         Sources : constant Files.Path_List := Files.List_Tree (Root, Name_Pattern);
      begin
         for Path of Sources loop
            declare
               Found : constant String := First_In_File (U.To_String (Path));
            begin
               if Found /= "" then
                  return Found;
               end if;
            end;
         end loop;

         return "";
      end First_In_Tree;

      Found : constant String := First_In_Tree ("*.ads");
   begin
      if Found /= "" then
         return Found;
      end if;

      return First_In_Tree ("*.adb");
   end First_Unknown_Production_Key_Literal;

   procedure Require_Production_Key_Literals
     (Root : String := "../src")
   is
      Unknown_Key : constant String := First_Unknown_Production_Key_Literal (Root);
   begin
      if Unknown_Key /= "" then
         Project_Tools.Release_Checks.Fail
           ("production message key literal must be catalog-required: " & Unknown_Key);
      end if;
   end Require_Production_Key_Literals;
end Awk_Workflow_Message_Key_Policy;
