/* Enunciado: crear un sistema de evaluaciones universitarias, en el que un profesor pueda publicar las notas de las 
evaluaciones de sus alumnos y ellos puedan visualizarlas. También cada alumno puede solicitar la revisión de su examen
ingresando su ID en caso de no estar satisfecho con el resultado de su examen, y quedar anotado en una lista. Luego el 
profesor podrá ver la lista de los alumnos anotados para revisión y cambiar la nota a quienes considere. De esa forma
actualiza los resultados y podrán ser vistas por los alumnos.
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 < 0.7.0;
pragma experimental ABIEncoderV2;

// -----------------------------------
//  ALUMNO   |    ID    |      NOTA
// -----------------------------------
//  Marcos |    77755N    |      5
//  Joan   |    12345X    |      9
//  Maria  |    02468T    |      2
//  Marta  |    13579U    |      3
//  Alba   |    98765Z    |      5

contract notas {
    
    // Direccion del profesor (dueño del contrato)
    address public profesor;
 
    constructor () public {
        profesor = msg.sender;
    }
    
    // Matchear el hash de la identidad del alumno con su nota del examen
    mapping (bytes32 => uint) Notas;
    
    // Lista de alumnos que piden revisiones de examen
    string [] revisiones;
    
    // Eventos 
    event alumno_evaluado(bytes32);
    event evento_revision(string);
    
    // Evaluar alumnos
    // Matchear el hash de la identidad del alumno con su nota del examen y emitir el evento
    function Evaluar(string memory _idAlumno, uint _nota) public UnicamenteProfesor(msg.sender){

        bytes32 hash_idAlumno = keccak256(abi.encodePacked(_idAlumno));

        Notas[hash_idAlumno] = _nota;

        emit alumno_evaluado(hash_idAlumno);
    }
    
    // Visualizar la nota de un alumno 
    function VerNotas(string memory _idAlumno) public view returns(uint) {
        
        bytes32 hash_idAlumno = keccak256(abi.encodePacked(_idAlumno));
        
        return Notas[hash_idAlumno];
    } 
    
    // Funcion para pedir una revision del examen
    // Registrar al alumno dentro de la lista de revisiones, y emitir el evento
    function Revision(string memory _idAlumno) public {

        revisiones.push(_idAlumno);

        emit evento_revision(_idAlumno);
    }
    
    // Visualizar la lista de alumnos que han solicitado revision de examen
    function VerRevisiones() public view UnicamenteProfesor(msg.sender) returns (string [] memory){

        return revisiones;
    }

    // Restringir la función para que sea ejecutable solo por el profesor
    modifier UnicamenteProfesor(address _direccion){

        require(_direccion == profesor, "Usuario no autorizado para ejecutar esta funcion");
        _;
    }
}
