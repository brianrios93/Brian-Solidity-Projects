/*Enunciado:

Crear un sistema para gestionar las transacciones dentro de un parque de diversiones como Disney utilizando un 
token ERC20. Para esto se seguirá la implementación realizada por OpenZepellin con algunos pequeños cambios adaptados a esta
aplicación. 
Este token será generado automáticamente por el contrato de Disney, y utilizado para que los clientes puedan pagar por 
disfrutar atracciones y consumir comidas.
El dueño de este contrato será Disney, y es quien podrá dar de alta y de baja nuevas atracciones y comidas. Luego, 
los clientes comprarán la cantidad de tokens que deseen para pagar las atracciones y las comidas. Al final del paseo, 
podrán devolver los tokens que no hayan utilizado y recuperarán su dinero (en Ethers).
Este contrato tiene una opción para consultar la dirección del contrato del token creado (con nombre DSN) para poder
visualizarlo en la BSCScan, Metamask o donde se lo prefiera.

PD: este sistema representa una mejora respecto al modo tradicional en el que se paga un boleto por todas las atracciones, 
ya que en muchos casos las personas no llegan a utilizarlas todas. De este modo, solo se paga por las que sí se utilizan,
y ahorran dinero.
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract Disney{

    // ------------------------------------------- DECLARACIONES INICIALES -------------------------------------------

    //La librería SafeMath se encuentra entro de ERC20.sol
    using SafeMath for uint256;
    
    //Dirección de Disney (owner)
    address public owner;

    //Instancia al contrato Token
    ERC20Basic private token;

    //Valor de cambio de moneda Token/Ether. Valor 1 equivale a 0.01 Ether, valor 100 equivale a 100 Ether
    //Se trabaja con fracciones de Ether porque los Faucet de internet existentes entregan solo fracciones de Ether.
    uint valortoken; 
    address public direccion_token;

    constructor(uint _totaltokens, uint _valortoken) public{
        token = new ERC20Basic(_totaltokens, "Disney Token", "DSN"); //Creación del token
        valortoken = _valortoken;
        direccion_token = address(token);
        owner = msg.sender;
    }

    //Estructura para almacenar información sobre la actividad de los clientes
    //Se almacena información sobre la cantidad de tokens que poseen, nombre de atracciones disfrutadas y comidas pedidas
    struct struct_comidas_pedidas{
        uint cantidad;
        string comida;
    }
    
    struct cliente{
        uint tokens_comprados;
        string [] atracciones_disfrutadas; //Para ir almacenando la lista de todas las atracciones que realiza
        struct_comidas_pedidas [] comidas_pedidas;
    }

    //Matchear la dirección de los clientes con la información de su actividad
    mapping (address => cliente) public map_clientes;

    // ------------------------------------------- GESTIÓN DE TOKENS -------------------------------------------

    event comprando_tokens(uint, address);

    //Establecer el precio de un token
    function Precio_tokens(uint _numTokens) internal view returns (uint){

        return _numTokens*valortoken*(0.01 ether);
    }

    //El cliente paga con Ethers y recibe tokens
    function Comprar_tokens(uint _cantTokens) public payable{
        
        //Calcular el costo de comprar la cantidad de tokens especificada
        uint costo = Precio_tokens(_cantTokens);
        
        //Verificar que el comprador posea el dinero suficiente para comprar los tokens que especifica
        require(costo <= msg.value, "Monto insuficiente. Ingrese más Ethers o compre menos tokens");

        //Devolver el cambio al cliente, es decir, la diferencia entre lo que paga y el costo de los tokens
        uint return_value = msg.value - costo;
        msg.sender.transfer(return_value); 

        //Verificar que el número de tokens a comprar sea menor o igual que los que están disponibles en el contrato
        uint balance = token.balanceOf(address(this));
        require(_cantTokens <= balance, "No se dispone de esa cantidad de tokens. Ingrese un número menor");

        //Transferir tokens al cliente
        token.transfer(msg.sender, _cantTokens); 

        //Registramos la cantidad de tokens comprada en la estructura de la información de clientes
        map_clientes[msg.sender].tokens_comprados = token.balanceOf(msg.sender);

        //Evento de compra de tokens
        emit comprando_tokens(_cantTokens, msg.sender);
    }

    //El cliente devuelve los tokens a este contrato y recibe el correspondiente valor en Ethers
    function DevolverTokens(uint _numTokens) public{

        require(_numTokens <= token.balanceOf(msg.sender),"Error. Ingrese una cantidad menor o igual a los tokens que posee");

        //Devolver los tokens al Smart Contract de Disney:
        token.transferClient(msg.sender, address(this), _numTokens);

        /*Transferir la cantidad equivalente de los tokens en Ethers al cliente. La función precio_tokens se
        encarga de hacer la conversión
        */
        msg.sender.transfer(Precio_tokens(_numTokens));
    }

    //Consultar la cantidad de tokens disponibles para comprar
    function Tokens_disponibles() public view returns (uint){
        return token.balanceOf(address(this));
    }

    //Consultar la cantidad de Ethers transferidas a este contrato. 
    function Ethers_contrato() public view returns(uint){
    //    return (address(this).balance)/1 ether;   //Por si se quiere manejar unidades enteras de Ether
        return (address(this).balance);  
    }

    //Consultar el balance de tokens actual
    function Mis_tokens() public view returns(uint){
        return token.balanceOf(msg.sender);
    }

    //Función para agregar más cantidad Tokens al contrato. Solo debe ser ejecutable por el owner.
    function Generar_Tokens(uint _numTokens) public Solo_owner(msg.sender){
        token.increaseTotalSupply(_numTokens);
    }

    //Restringir funciones solo al dueño del contrato
    modifier Solo_owner(address _direccion){
        require (_direccion == owner, "No tienes autorización para ejecutar esta función");
        _;
    }

    // ------------------------------------------- GESTIÓN DE DISNEY -------------------------------------------

    //Cada atracción debe tener asociado una cantidad de tokens a pagar para poder acceder. Por ejemplo:
    //Tarzan -> 2 tokens
    //Hercules -> 5 tokens
    //Rey Leon -> 8 tokens

    //Eventos que vamos a querer
    event disfruta_atraccion(string, uint, address);
    event alta_atraccion(string, uint);
    event baja_atraccion(string);

    //Estructura de cada atracción
    struct atraccion{
        string nombre_atraccion;
        uint precio_atraccion;
        bool estado_atraccion; //TRUE -> Atracción activa, FALSE -> Atracción inactiva
    }

    //Relacionar el nombre de una atracción con su información
    mapping (string => atraccion) public map_atraccion;

    //Lista del nombre de todas las atracciones
    string[] lista_atracciones;

    //Relacionar un cliente con la lista de atracciones a las que accede (su historial)
    mapping (address => string[]) historial_atracciones;

    //Creación de una nueva atracción. Solo ejecutable por el owner.
    function NuevaAtraccion(string memory _nombreAtraccion, uint _precioAtraccion) public Solo_owner(msg.sender){

        //Se la inicializa ya dada de alta, con el estado en TRUE
        map_atraccion[_nombreAtraccion] = atraccion(_nombreAtraccion, _precioAtraccion, true);

        lista_atracciones.push(_nombreAtraccion);
       
        emit alta_atraccion(_nombreAtraccion, _precioAtraccion);

    }

    //Dar de baja una atracción. Solo ejecutable por Disney (owner)
    function BajaAtraccion(string memory _nombreAtraccion) public Solo_owner(msg.sender){

        //Verificar que la atracción exista y esté previamente dada de alta
        require(map_atraccion[_nombreAtraccion].estado_atraccion == true, "La atracción indicada está dada de baja o no existe");

        map_atraccion[_nombreAtraccion].estado_atraccion = false;

        emit baja_atraccion(_nombreAtraccion);
    }

    //Visualizar la lista de todas las atracciones (activas o inactivas)
    function VerAtracciones() public view returns(string[] memory){
       
        return lista_atracciones;
    }

    //Visualizar las atracciones activas
    function AtraccionesDisponibles() public view returns(string [] memory){
    
        string [] memory a = new string[](lista_atracciones.length);
        uint posicion = 0;
    
        for(uint i=0; i<lista_atracciones.length;i++){
            if (map_atraccion[lista_atracciones[i]].estado_atraccion == true){
                a[posicion] = lista_atracciones[i];
                posicion++;
            }
        }
        return a;
    }

    //Pagar por utilizar una atracción
    function DisfrutarAtraccion(string memory _atraccion) public{

        //Creamos esta variable para simplificar la longitud del código
        uint num_tokens = map_atraccion[_atraccion].precio_atraccion;
        
        require(map_atraccion[_atraccion].estado_atraccion == true, "La atracción no existe o está dada de baja");

        //Verificar que el cliente pueda pagar por esta atracción
        require(num_tokens <= token.balanceOf(msg.sender), "Tokens insuficientes para esta atracción");

        //Transferir los tokens desde el cliente hacia este contrato
        token.transferClient(msg.sender, address(this), num_tokens);

        historial_atracciones[msg.sender].push(_atraccion);

        map_clientes[msg.sender].tokens_comprados = token.balanceOf(msg.sender);
        map_clientes[msg.sender].atracciones_disfrutadas.push(_atraccion);

        emit disfruta_atraccion(_atraccion, num_tokens, msg.sender);
    }

    //Visualizar el historial de atracciones que disfrutó un cliente
    function Historial_Atraccion() public view returns(string[] memory){
        return historial_atracciones[msg.sender];
    }

    //Visualizar toda la información de un cliente: tokens que tiene, y las atracciones que disfrutó
    function Info_clientes() public view returns(cliente memory){
        return map_clientes[msg.sender];
    }    

    //----------------------------------------------GESTION DE COMIDAS----------------------------------------

    //Cada comida debe tener asociado una cantidad de tokens a pagar para poder consumir. Por ejemplo:
    //Bebida -> 2 tokens
    //Hamburguesa -> 5 tokens
    //Helado -> 8 tokens

    //Eventos
    event disfruta_comida(string, uint, uint, address);
    event alta_comida(string, uint);
    event baja_comida(string);

    //Estructura de cada comida
    struct comida{
        string nombre_comida;
        uint precio_comida;
        bool estado_comida; //TRUE -> Comida activa, FALSE -> Comida inactiva (se terminó, o no se sirve más por ahora)
    }

    //Relacionar el nombre de una comida con su estructura
    mapping (string => comida) public map_comida;

    //Lista de todas las comidas
    string[] lista_comidas;

    //Creación de una comida
    function Alta_Comida(string memory _comida, uint _precio) public Solo_owner(msg.sender){

        map_comida[_comida] = comida(_comida, _precio, true);
        
        lista_comidas.push(_comida);
       
        emit alta_comida(_comida, _precio);
    }

    //Dar de baja una comida
    function Baja_Comida(string memory _comida) public Solo_owner(msg.sender){

        require(map_comida[_comida].estado_comida == true, 
        "La comida indicada está no está disponible actualmente o no existe");

        map_comida[_comida].estado_comida = false;

        emit baja_comida(_comida);
    }    

    //Visualizar lista de comidas activas
    function Ver_comidas_disponibles() public view returns(string[] memory){
        
        string [] memory a = new string[](lista_comidas.length);
        uint posicion = 0;
    
        for(uint i=0; i<lista_comidas.length;i++){
            if (map_comida[lista_comidas[i]].estado_comida == true){
                a[posicion] = lista_comidas[i];
                posicion++;
            }
        }
        return a;

    }

    //Pagar por pedir una comida. Se debe especificar nombre y cantidad: por ejemplo "Hamburguesa, 2"
    function Pedir_Comida(string memory _comida, uint _cantidad) public{
        
        require(map_comida[_comida].estado_comida == true, 
        "La comida indicada está no está disponible actualmente o no existe");

        uint num_tokens = _cantidad.mul(map_comida[_comida].precio_comida);

        require(num_tokens <= token.balanceOf(msg.sender), "Tokens insuficientes para esta compra");

        token.transferClient(msg.sender, address(this), num_tokens);

        map_clientes[msg.sender].tokens_comprados = token.balanceOf(msg.sender);
        map_clientes[msg.sender].comidas_pedidas.push(struct_comidas_pedidas(_cantidad, _comida));

        emit disfruta_comida(_comida, _cantidad, num_tokens, msg.sender);
    }

}
