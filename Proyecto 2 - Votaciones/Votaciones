Enunciado:

Crear un sistema de votaciones con registros en la blockchain, en la que cualquier persona se pueda postular como candidato
para unas elecciones. Estas pueden ser para cualquier temática, ya sea la elección de un presidente de un país como elegir
el delegado de una clase en la escuela. Para este proyecto es indistinto.
Luego, todas las personas de un grupo podrán votar para obtener así un ganador. Se debe poder conocer la cantidad de votos de cada candidato en cualquier momento, y luego el ganador, quien será la persona
que haya obtenido la mayor cantidad de votos.
*/

// SPDX-Licence-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;

// Candidatos de ejemplo:
// -----------------------------------
//  CANDIDATO   |   EDAD   |      ID
// -----------------------------------
//  Toni        |    20    |    12345X
//  Alberto     |    23    |    54321T
//  Joan        |    21    |    98765P
//  Javier      |    19    |    56789W

contract Votaciones{

    address public owner;

    constructor() public{
        owner = msg.sender;
    }

    //Matchear el nombre del candidato con el hash de sus datos personales (para ocultar información sensible)
    mapping(string => bytes32) map_candidatos; 
    
    //Matchear el nombre del candidato con la cantidad de votos que obtiene
    mapping(string => uint) map_votos;

    //Lista para almacenar el nombre de los candidatos
    string[] candidatos;

    //Lista para almacenar el hash del nombre de los votantes
    bytes32[] votantes;

    //Postularse como candidato (cualquier persona puede hacerlo)
    function Postularse(string memory _nombre, uint _edad, string memory _idPersona) public{

        candidatos.push(_nombre);

        bytes32 hash_candidato = keccak256(abi.encodePacked(_nombre, _edad, _idPersona));
        map_candidatos[_nombre] = hash_candidato;
    }

    //Ver la lista de candidatos que se postularon
    function Ver_candidatos() public view returns (string [] memory){

        return candidatos;
    }

    //Votar un candidato
    function Votar(string memory _nombre) public Votar_una_vez(msg.sender) Verificar_voto(_nombre){

        map_votos[_nombre]++; 
    }

    //Restringir la votación a una sola vez
    modifier Votar_una_vez(address _direccion){
        
        bytes32 hash_votantes = keccak256(abi.encodePacked(_direccion));
        
        for(uint i=0; i<votantes.length; i++){
            require(votantes[i] != hash_votantes, "Error. Voto ya registrado, no se permite más de una vez");
        }

        votantes.push(hash_votantes);
        _;
    }

    //Verificar que se haya votado por un candidato existente
    modifier Verificar_voto(string memory _nombre){
        
        bool coincide = false; 
        
        for(uint i=0; i<candidatos.length; i++){
            if(keccak256(abi.encodePacked(candidatos[i]))  == keccak256(abi.encodePacked(_nombre))){
                coincide = true;
            }
        }
            if(coincide == false){
            require(false, "Este candidato no existe. elija otro");
            }       
        
        _;
    }

    //Ver la cantidad de votos de un candidato
    function Ver_Votos(string memory _nombre) public view Verificar_voto(_nombre) returns (uint){

        return map_votos[_nombre];
    }

    //Mostrar resultados en forma de string que enliste cada candidato con la cantidad de votos que obtuvo hasta el momento
    function Resultados() public view returns(string memory){
        
        string memory resultados_candidatos = "";//La iniciamos vacía para ir llenándola

        for(uint i=0; i<candidatos.length; i++){
            resultados_candidatos = string(abi.encodePacked(resultados_candidatos, "(", candidatos[i] ,", ", uint2str(map_votos[candidatos[i]]) ,") - "));
        }

        return resultados_candidatos;
    }

     //Mostrar los resultados finales de las votaciones en forma de lista (array)

    struct votos_candidato{
                string nombre;
                uint votos;
            } 

     function Resultados_lista() public view returns(votos_candidato [] memory){
    
        votos_candidato [] memory a = new votos_candidato[](candidatos.length);
        uint posicion = 0;
    
        for(uint i=0; i<candidatos.length;i++){
            
            a[posicion] = votos_candidato(candidatos[i], map_votos[candidatos[i]]);
            posicion++;
        }
        return a;
    }

    //Conocer el resultado final de las elecciones a indicar si ha habido empate
    function Ganador() public view returns(string memory){

        string memory ganador = candidatos[0]; //Inicializando en el primer valor ahorramos un ciclo de for
        bool flag = false;  //Flag para indicar si hay empate o no

        for(uint i=1; i < candidatos.length; i++){

            if(map_votos[ganador] < map_votos[candidatos[i]]){
                ganador = candidatos[i]; //Se encuentra un valor más grande que el actual
                flag = false;
            }
            else{
                if(map_votos[ganador] == map_votos[candidatos[i]]){
                    flag = true;
                }
            }
        }

        if(flag == true){
            ganador = "Hay un empate";
        }

        return ganador;

    }

    //Funcion auxiliar que transforma un uint a un string
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

}
