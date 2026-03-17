ibrary IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity calculadora is
Port (
SW : in STD_LOGIC_VECTOR(9 downto 0);
HEX0 : out STD_LOGIC_VECTOR(6 downto 0);
HEX1 : out STD_LOGIC_VECTOR(6 downto 0);
HEX2 : out STD_LOGIC_VECTOR(6 downto 0);
HEX3 : out STD_LOGIC_VECTOR(6 downto 0)
);
end calculadora;

architecture Behavioral of calculadora is

-- Entradas separadas
signal A_bin, B_bin : STD_LOGIC_VECTOR(3 downto 0);
signal OP : STD_LOGIC_VECTOR(1 downto 0);

-- Validación
signal A_ok, B_ok, ERROR : STD_LOGIC;

-- Resultados intermedios
signal suma : STD_LOGIC_VECTOR(4 downto 0);
signal resta_mag : STD_LOGIC_VECTOR(3 downto 0);
signal resta_sign: STD_LOGIC;
signal mult : STD_LOGIC_VECTOR(7 downto 0);

-- Resultado final en binario
signal R_bin : STD_LOGIC_VECTOR(7 downto 0);

-- Dígitos a mostrar
signal tens, ones : STD_LOGIC_VECTOR(3 downto 0);
signal A_dec, B_dec : STD_LOGIC_VECTOR(3 downto 0);

-- Modo error para mostrar EE en resultado
signal modo_error : STD_LOGIC;

-- Función para convertir un número BCD a 7 segmentos
-- Patrones activos en bajo, como en la DE0
function to_7seg(x : STD_LOGIC_VECTOR(3 downto 0)) return STD_LOGIC_VECTOR is
begin
case x is
when "0000" => return "1000000"; -- 0
when "0001" => return "1111001"; -- 1
when "0010" => return "0100100"; -- 2
when "0011" => return "0110000"; -- 3
when "0100" => return "0011001"; -- 4
when "0101" => return "0010010"; -- 5
when "0110" => return "0000010"; -- 6
when "0111" => return "1111000"; -- 7
when "1000" => return "0000000"; -- 8
when "1001" => return "0010000"; -- 9
when "1110" => return "0000110"; -- E
when others => return "1111111"; -- apagado
end case;
end function;

begin

------------------------------------------------------------------
-- BLOQUE 1: ASIGNACIÓN DE ENTRADAS
------------------------------------------------------------------
A_bin <= SW(3 downto 0); -- Operando A
B_bin <= SW(7 downto 4); -- Operando B
OP <= SW(9 downto 8); -- Operación

------------------------------------------------------------------
-- BLOQUE 2: VALIDACIÓN BCD
-- Verifica que A y B estén entre 0 y 9
------------------------------------------------------------------
process(A_bin, B_bin)
begin
if unsigned(A_bin) <= 9 then
A_ok <= '1';
else
A_ok <= '0';
end if;

if unsigned(B_bin) <= 9 then
B_ok <= '1';
else
B_ok <= '0';
end if;

-- CORRECCIÓN IMPORTANTE:
-- ERROR se calcula directamente con A_bin y B_bin,
-- no con A_ok y B_ok, para evitar usar valores viejos.
if (unsigned(A_bin) > 9) or (unsigned(B_bin) > 9) then
ERROR <= '1';
else
ERROR <= '0';
end if;
end process;

------------------------------------------------------------------
-- BLOQUE 3: UNIDAD ARITMÉTICA
-- Calcula suma, resta y multiplicación
------------------------------------------------------------------
process(A_bin, B_bin, OP)
variable A_int, B_int : integer range 0 to 15;
begin
A_int := to_integer(unsigned(A_bin));
B_int := to_integer(unsigned(B_bin));

-- Valores por defecto
suma <= (others => '0');
resta_mag <= (others => '0');
resta_sign <= '0';
mult <= (others => '0');

case OP is
when "00" => -- SUMA
suma <= std_logic_vector(resize(unsigned(A_bin) + unsigned(B_bin), 5));

when "01" => -- RESTA
if A_int >= B_int then
resta_mag <= std_logic_vector(unsigned(A_bin) - unsigned(B_bin));
resta_sign <= '0';
else
resta_mag <= std_logic_vector(unsigned(B_bin) - unsigned(A_bin));
resta_sign <= '1';
end if;

when "10" | "11" => -- MULTIPLICACIÓN
mult <= std_logic_vector(resize(unsigned(A_bin) * unsigned(B_bin), 8));

when others =>
null;
end case;
end process;

------------------------------------------------------------------
-- BLOQUE 4: MUX DE SELECCIÓN DEL RESULTADO
-- Escoge qué operación se envía al bloque de visualización
------------------------------------------------------------------
process(OP, suma, resta_mag, mult)
begin
case OP is
when "00" => -- suma
R_bin <= "000" & suma; -- 5 bits -> 8 bits
when "01" => -- resta
R_bin <= "0000" & resta_mag; -- 4 bits -> 8 bits
when "10" | "11" => -- multiplicación
R_bin <= mult;
when others =>
R_bin <= (others => '0');
end case;
end process;

------------------------------------------------------------------
-- BLOQUE 5: CONVERSIÓN BINARIO A DECENAS Y UNIDADES
-- Si hay error BCD, muestra EE en el resultado
------------------------------------------------------------------
process(R_bin, ERROR)
variable valor : integer range 0 to 255;
begin
if ERROR = '1' then
tens <= "1010"; -- E
ones <= "1010"; -- E
modo_error <= '1';
else
valor := to_integer(unsigned(R_bin));

if valor >= 100 then
-- Si el resultado no cabe en 2 displays decimales,
-- también se muestra EE
tens <= "1010";
ones <= "1010";
modo_error <= '1';
elsif valor >= 10 then
tens <= std_logic_vector(to_unsigned(valor / 10, 4));
ones <= std_logic_vector(to_unsigned(valor mod 10, 4));
modo_error <= '0';
else
tens <= "0000";
ones <= std_logic_vector(to_unsigned(valor, 4));
modo_error <= '0';
end if;
end if;
end process;

------------------------------------------------------------------
-- BLOQUE 6: PREPARACIÓN DE A Y B PARA DISPLAY
-- Si un operando no es BCD válido, se muestra E
------------------------------------------------------------------
A_dec <= A_bin when A_ok = '1' else "1110";
B_dec <= B_bin when B_ok = '1' else "1110";

------------------------------------------------------------------
-- BLOQUE 7: SALIDA A 7 SEGMENTOS
------------------------------------------------------------------
HEX3 <= to_7seg(A_dec); -- Muestra A
HEX2 <= to_7seg(B_dec); -- Muestra B
HEX1 <= to_7seg(tens); -- Decenas del resultado
HEX0 <= to_7seg(ones); -- Unidades del resultado

end Behavioral;
