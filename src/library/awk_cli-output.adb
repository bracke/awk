with Awk_Config;
with Ada.Strings.Unbounded;
with Awk_CLI.Execution;
with Terminal_Styles;

package body Awk_CLI.Output is
   package L renames Awk_CLI.Localization;
   package D renames Awk_CLI.Diagnostics;

   function Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      if Raw'Length > 0 and then Raw (Raw'First) = ' ' then
         return Raw (Raw'First + 1 .. Raw'Last);
      else
         return Raw;
      end if;
   end Image;

   procedure Set_Color (Mode : Awk_CLI.Options.Color_Mode) is
   begin
      case Mode is
         when Awk_CLI.Options.Color_Auto =>
            Terminal_Styles.Set_Color_Policy (Terminal_Styles.Color_Auto);
         when Awk_CLI.Options.Color_Always =>
            Terminal_Styles.Set_Color_Policy (Terminal_Styles.Color_Always);
         when Awk_CLI.Options.Color_Never =>
            Terminal_Styles.Set_Color_Policy (Terminal_Styles.Color_Never);
      end case;
   end Set_Color;

   function Styled
     (Text : String;
      Role : Terminal_Styles.Style_Role;
      Destination_Is_Terminal : Boolean) return String is
     (Terminal_Styles.Decorate (Text, Role, Destination_Is_Terminal));

   function Help
     (Catalog : L.Catalog;
      Destination_Is_Terminal : Boolean) return String
   is
      LF : constant String := [1 => ASCII.LF];
   begin
      return
        Styled (L.Text (Catalog, "awk.help.title"), Terminal_Styles.Role_Header,
                Destination_Is_Terminal) & LF &
        L.Text (Catalog, "awk.help.summary") & LF & LF &
        L.Text (Catalog, "awk.help.usage.direct_program") & LF &
        L.Text (Catalog, "awk.help.usage.program_files") & LF & LF &
        L.Text (Catalog, "awk.help.options.field_separator") & LF &
        L.Text (Catalog, "awk.help.options.variable") & LF &
        L.Text (Catalog, "awk.help.options.program_file") & LF &
        L.Text (Catalog, "awk.help.options.color") & LF &
        L.Text (Catalog, "awk.help.options.help") & LF &
        L.Text (Catalog, "awk.help.options.version") & LF &
        L.Text (Catalog, "awk.help.options.terminator") & LF & LF &
        L.Text (Catalog, "awk.help.operands") & LF &
        L.Text (Catalog, "awk.help.stdin") & LF &
        L.Text (Catalog, "awk.help.exit_statuses") & LF & LF &
        Styled (L.Text (Catalog, "awk.help.compatibility.heading"), Terminal_Styles.Role_Header,
                Destination_Is_Terminal) & LF &
        L.Text (Catalog, "awk.help.compatibility.awklib_limitations") & LF;
   end Help;

   function Version (Catalog : L.Catalog) return String is
      LF : constant String := [1 => ASCII.LF];
   begin
      return
        L.Text (Catalog, "awk.version.program",
                "version", Awk_Config.Crate_Version) & LF &
        L.Text (Catalog, "awk.version.interpreter",
                "version", Awk_CLI.Execution.Interpreter_Version) & LF &
        L.Text (Catalog, "awk.version.license") & LF;
   end Version;

   function Source_Display_Name (Catalog : L.Catalog; Source_Name : String) return String is
   begin
      if Source_Name = "awk.source.command_line" then
         return L.Text (Catalog, Source_Name);
      else
         return Source_Name;
      end if;
   end Source_Display_Name;

   function Diagnostic_Text
     (Catalog : L.Catalog;
      Item    : D.Diagnostic;
      Destination_Is_Terminal : Boolean) return String
   is
      LF     : constant String := [1 => ASCII.LF];
      Label  : constant String := L.Label (Catalog, Item.Severity);
      Result : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.To_Unbounded_String
          (Styled
             (L.Text
                (Catalog,
                 "awk.diagnostic.header",
                 "severity",
                 Label,
                 L.Primary (Catalog, Item)),
              Terminal_Styles.Role_Error,
              Destination_Is_Terminal));
   begin
      if Ada.Strings.Unbounded.Length (Item.Source_Name) > 0
        and then Item.Line > 0
      then
         declare
            Location : constant String :=
              Image (Item.Line)
              & (if Item.Column > 0 then ":" & Image (Item.Column) else "");
         begin
            Ada.Strings.Unbounded.Append
              (Result,
               LF & L.Text
                 (Catalog,
                  "awk.diagnostic.source_location",
                  "path",
                  Source_Display_Name
                    (Catalog, Ada.Strings.Unbounded.To_String (Item.Source_Name)),
                  Location));
         end;
      end if;
      if Ada.Strings.Unbounded.Length (Item.Detail) > 0 then
         Ada.Strings.Unbounded.Append
           (Result,
            LF & L.Text
              (Catalog,
               "awk.diagnostic.detail",
               Detail => Ada.Strings.Unbounded.To_String (Item.Detail)));
      end if;
      if Ada.Strings.Unbounded.Length (Item.Hint_Id) > 0 then
         Ada.Strings.Unbounded.Append
           (Result,
            LF & L.Text (Catalog, "awk.diagnostic.hint",
                         "detail", L.Text (Catalog, Ada.Strings.Unbounded.To_String (Item.Hint_Id))));
      end if;
      Ada.Strings.Unbounded.Append (Result, LF);
      return Ada.Strings.Unbounded.To_String (Result);
   end Diagnostic_Text;
end Awk_CLI.Output;
