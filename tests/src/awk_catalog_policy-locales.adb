with Ada.Strings.Unbounded;

package body Awk_Catalog_Policy.Locales is
   package U renames Ada.Strings.Unbounded;

   Supported : constant array (Positive range <>) of U.Unbounded_String :=
     [U.To_Unbounded_String ("az"),
      U.To_Unbounded_String ("be"),
      U.To_Unbounded_String ("bg"),
      U.To_Unbounded_String ("bs"),
      U.To_Unbounded_String ("ca"),
      U.To_Unbounded_String ("cnr"),
      U.To_Unbounded_String ("cs"),
      U.To_Unbounded_String ("da"),
      U.To_Unbounded_String ("de"),
      U.To_Unbounded_String ("el"),
      U.To_Unbounded_String ("en"),
      U.To_Unbounded_String ("es"),
      U.To_Unbounded_String ("et"),
      U.To_Unbounded_String ("fi"),
      U.To_Unbounded_String ("fr"),
      U.To_Unbounded_String ("ga"),
      U.To_Unbounded_String ("hr"),
      U.To_Unbounded_String ("hu"),
      U.To_Unbounded_String ("hy"),
      U.To_Unbounded_String ("is"),
      U.To_Unbounded_String ("it"),
      U.To_Unbounded_String ("ka"),
      U.To_Unbounded_String ("kk"),
      U.To_Unbounded_String ("la"),
      U.To_Unbounded_String ("lb"),
      U.To_Unbounded_String ("lt"),
      U.To_Unbounded_String ("lv"),
      U.To_Unbounded_String ("mk"),
      U.To_Unbounded_String ("mt"),
      U.To_Unbounded_String ("nl"),
      U.To_Unbounded_String ("no"),
      U.To_Unbounded_String ("pl"),
      U.To_Unbounded_String ("pt"),
      U.To_Unbounded_String ("rm"),
      U.To_Unbounded_String ("ro"),
      U.To_Unbounded_String ("ru"),
      U.To_Unbounded_String ("sk"),
      U.To_Unbounded_String ("sl"),
      U.To_Unbounded_String ("sq"),
      U.To_Unbounded_String ("sr"),
      U.To_Unbounded_String ("sv"),
      U.To_Unbounded_String ("tr"),
      U.To_Unbounded_String ("uk")];

   function Count return Positive is
   begin
      return Supported'Length;
   end Count;

   function Item (Index : Positive) return String is
   begin
      return U.To_String (Supported (Index));
   end Item;

   function Primary (Locale : String) return String is
      Last : Natural := Locale'Last;
   begin
      for Index in Locale'Range loop
         if Locale (Index) = '-' or else Locale (Index) = '_'
           or else Locale (Index) = '.'
         then
            Last := Index - 1;
            exit;
         end if;
      end loop;

      if Last < Locale'First then
         return "";
      end if;

      return Locale (Locale'First .. Last);
   end Primary;

   function Contains (Locale : String) return Boolean is
      Candidate : constant String := Primary (Locale);
   begin
      for Supported_Locale of Supported loop
         if Candidate = U.To_String (Supported_Locale) then
            return True;
         end if;
      end loop;
      return False;
   end Contains;
end Awk_Catalog_Policy.Locales;
