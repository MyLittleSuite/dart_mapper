import 'package:dart_mapper/dart_mapper.dart';
import 'package:source_gen_test/annotations.dart';

class SourceNode {
  final String label;
  final SourceNode? next;

  const SourceNode(this.label, this.next);
}

class TargetNode {
  final String label;
  final TargetNode? next;

  const TargetNode(this.label, this.next);
}

@ShouldGenerate(
  r'''class NodeMapperImpl extends NodeMapper {
  const NodeMapperImpl();

  @override
  TargetNode toTarget(SourceNode source) {
    return TargetNode(
      source.label,
      source.next != null ? toTarget(source.next!) : null,
    );
  }
}''',
  contains: true,
)
@Mapper()
abstract class NodeMapper {
  const NodeMapper();

  TargetNode toTarget(SourceNode source);
}
