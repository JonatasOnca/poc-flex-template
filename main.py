# main.py
import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions, SetupOptions

class CustomPipelineOptions(PipelineOptions):
    """Define as opções customizadas para o pipeline."""
    @classmethod
    def _add_argparse_args(cls, parser):
        parser.add_argument(
            '--input',
            required=True,
            help='GCS path for the input file (e.g., gs://bucket/input.txt)')
        parser.add_argument(
            '--output',
            required=True,
            help='GCS path prefix for the output file (e.g., gs://bucket/output/result)')

def run():
    """Constrói e executa o pipeline do Apache Beam."""
    pipeline_options = PipelineOptions()
    custom_options = pipeline_options.view_as(CustomPipelineOptions)
    
    # Necessário para instalar dependências nos workers do Dataflow
    pipeline_options.view_as(SetupOptions).save_main_session = True

    with beam.Pipeline(options=pipeline_options) as p:
        (p
         | 'ReadFile' >> beam.io.ReadFromText(custom_options.input)
         | 'ToUpperCase' >> beam.Map(lambda line: line.upper())
         | 'WriteFile' >> beam.io.WriteToText(custom_options.output)
        )

if __name__ == '__main__':
    print("Iniciando o pipeline do Flex Template...")
    run()