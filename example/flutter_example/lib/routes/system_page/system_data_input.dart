import 'package:equations_solver/localization/localization.dart';
import 'package:equations_solver/routes/models/dropdown_value/inherited_dropdown_value.dart';
import 'package:equations_solver/routes/models/number_switcher/inherited_number_switcher.dart';
import 'package:equations_solver/routes/system_page/model/inherited_system.dart';
import 'package:equations_solver/routes/system_page/model/system_state.dart';
import 'package:equations_solver/routes/system_page/utils/dropdown_selection.dart';
import 'package:equations_solver/routes/system_page/utils/jacobi_initial_vector.dart';
import 'package:equations_solver/routes/system_page/utils/matrix_input.dart';
import 'package:equations_solver/routes/system_page/utils/size_picker.dart';
import 'package:equations_solver/routes/system_page/utils/sor_relaxation_factor.dart';
import 'package:equations_solver/routes/system_page/utils/vector_input.dart';
import 'package:flutter/material.dart';

/// This widget contains a [MatrixInput] widgets needed to parse the values of
/// the matrix of the system in the `Ax = b` equation.
class SystemDataInput extends StatefulWidget {
  /// Creates a [SystemDataInput] widget.
  const SystemDataInput({super.key});

  @override
  SystemDataInputState createState() => SystemDataInputState();
}

/// State of the [SystemDataInput] widget.
@visibleForTesting
class SystemDataInputState extends State<SystemDataInput> {
  /// The text input controllers for the matrix.
  ///
  /// This is asking for `A` in the `Ax = b` equation where:
  ///
  ///  - `A` is the matrix
  ///  - `b` is the known values vector
  late final matrixControllers = List<TextEditingController>.generate(
    16,
    _generateTextController,
  );

  /// The text input controllers for the vector.
  ///
  /// This is asking for `b` in the `Ax = b` equation where:
  ///
  ///  - `A` is the matrix
  ///  - `b` is the known values vector
  late final vectorControllers = List<TextEditingController>.generate(
    4,
    (index) => _generateTextController(index + 16),
  );

  /// The text input controllers for the initial guess vector of the Jacobi
  /// algorithm.
  late final jacobiControllers = List<TextEditingController>.generate(
    4,
    (index) => _generateTextController(index + 16 + 4),
  );

  /// A controller for the relaxation factor `w` of the SOR algorithm.
  late final wSorController = _generateTextController(16 + 4 + 4);

  /// Form validation key.
  final formKey = GlobalKey<FormState>();

  /// Caching the text that describes what the vector does.
  late final vectorText = Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
    child: Text(
      context.l10n.vector_description,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.grey,
      ),
    ),
  );

  /// Caching the text that describes what the matrix does.
  late final matrixText = Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
    child: Text(
      context.l10n.matrix_description,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.grey,
      ),
    ),
  );

  /// The widget asking for the relaxation factor `w` of the SOR algorithm.
  late final wInput = RelaxationFactorInput(
    textEditingController: wSorController,
  );

  /// This is required to figure out which system solving algorithm has to be
  /// used.
  SystemType get _getType => context.systemState.systemType;

  /// Generates the controllers and hooks them to the [TextFieldValuesCubit] in
  /// order to cache the user input.
  TextEditingController _generateTextController(int index) {
    // Initializing with the cached value, if any
    final controller = TextEditingController();

    return controller;
  }

  /// Form cleanup.
  void cleanInput() {
    for (final controller in matrixControllers) {
      controller.clear();
    }

    for (final controller in vectorControllers) {
      controller.clear();
    }

    for (final controller in jacobiControllers) {
      controller.clear();
    }

    wSorController.clear();

    // Making sure to also clear the form completely
    formKey.currentState?.reset();
    context.systemState.clear();
    context.numberSwitcherState.reset();

    FocusScope.of(context).unfocus();
  }

  /// Solves a system of equations.
  void solve() {
    if (formKey.currentState?.validate() ?? false) {
      final algorithm = context.dropdownValue.value;
      final size = context.numberSwitcherState.state;

      // Getting the inputs
      final systemInputs = matrixControllers.sublist(0, size * size).map((c) {
        return c.text;
      }).toList();

      final vectorInputs = vectorControllers.sublist(0, size).map((c) {
        return c.text;
      }).toList();

      // Solving the system
      switch (_getType) {
        case SystemType.rowReduction:
          context.systemState.rowReductionSolver(
            flatMatrix: systemInputs,
            knownValues: vectorInputs,
            size: size,
          );
          break;
        case SystemType.factorization:
          context.systemState.factorizationSolver(
            flatMatrix: systemInputs,
            knownValues: vectorInputs,
            size: size,
            method: SystemState.factorizationResolve(algorithm),
          );
          break;
        case SystemType.iterative:
          final initialGuesses = jacobiControllers.sublist(0, size).map((c) {
            return c.text;
          }).toList();

          context.systemState.iterativeSolver(
            flatMatrix: systemInputs,
            knownValues: vectorInputs,
            size: size,
            method: SystemState.iterativeResolve(algorithm),
            jacobiInitialVector: initialGuesses,
            w: wSorController.text,
          );
          break;
      }
    } else {
      // The user entered invalid values
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.invalid_values),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    wSorController.dispose();

    for (final controller in matrixControllers) {
      controller.dispose();
    }

    for (final controller in vectorControllers) {
      controller.dispose();
    }

    for (final controller in jacobiControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          // Some spacing
          const SizedBox(
            height: 60,
          ),

          // Size changer
          const SizePicker(),

          // Some spacing
          const SizedBox(
            height: 35,
          ),

          // Matrix input
          AnimatedBuilder(
            animation: context.numberSwitcherState,
            builder: (context, _) {
              return MatrixInput(
                matrixControllers: matrixControllers,
                matrixSize: context.numberSwitcherState.state,
              );
            },
          ),

          // The description associated to the matrix widget
          matrixText,

          // Some spacing
          const SizedBox(
            height: 30,
          ),

          // Vector input
          AnimatedBuilder(
            animation: context.numberSwitcherState,
            builder: (context, _) {
              return VectorInput(
                vectorControllers: vectorControllers,
                vectorSize: context.numberSwitcherState.state,
              );
            },
          ),

          // The description associated to the matrix widget
          vectorText,

          // Algorithm type picker
          const SystemDropdownSelection(),

          // The optional input for the relaxation value
          wInput,

          // The optional input for the initial guesses vector
          // Vector input
          AnimatedBuilder(
            animation: context.numberSwitcherState,
            builder: (context, _) {
              return JacobiVectorInput(
                controllers: jacobiControllers,
                vectorSize: context.numberSwitcherState.state,
              );
            },
          ),

          // Spacing
          const SizedBox(height: 45),

          // Two buttons needed to "solve" and "clear" the system
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Solving the equation
              ElevatedButton(
                key: const Key('System-button-solve'),
                onPressed: solve,
                child: Text(context.l10n.solve),
              ),

              // Some spacing
              const SizedBox(width: 30),

              // Cleaning the inputs
              ElevatedButton(
                key: const Key('System-button-clean'),
                onPressed: cleanInput,
                child: Text(context.l10n.clean),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
