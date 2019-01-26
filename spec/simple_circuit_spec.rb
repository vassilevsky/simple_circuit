require "spec_helper"

RSpec.describe SimpleCircuit do
  it "has a version number" do
    expect(SimpleCircuit::VERSION).not_to be nil
  end

  context 'happy path' do
    let(:foo){ Class.new{ def bar(baz); baz; end }.new }

    it 'passes through a message and returns the result' do
      expect(foo).to receive(:bar).with(:baz).and_call_original
      expect(SimpleCircuit.new(payload: foo).pass(:bar, :baz)).to eq(:baz)
    end
  end

  context 'when method call fails' do
    class BarError < RuntimeError; end

    let(:foo){ Class.new{ def bar; fail BarError; end }.new }
    let(:circuit){ SimpleCircuit.new(payload: foo) }

    it 'counts the error and lets it raise' do
      expect{circuit.pass(:bar)}.to raise_error(BarError)
    end

    context 'when circuit has too many errors' do
      let(:circuit){ SimpleCircuit.new(payload: foo, max_failures: 1) }

      it 'breaks the circuit - does not call the payload anymore, fails immediately' do
        expect(circuit).to be_closed
        expect{circuit.pass(:bar)}.to raise_error(BarError)
        expect(circuit).to be_closed
        expect(foo).to receive(:bar).and_call_original
        expect{circuit.pass(:bar)}.to raise_error(BarError)
        expect(circuit).not_to be_closed
        expect(circuit).to be_open
        expect(foo).not_to receive(:bar)
        expect{circuit.pass(:bar)}.to raise_error(BarError)
      end

      context 'testing circuit via logger' do
        let(:logger){ double(:logger, warn: true) }
        let(:circuit){ SimpleCircuit.new(payload: foo, max_failures: 1, logger: logger) }

        it 'does not break again' do
          expect{circuit.pass(:bar)}.to raise_error(BarError)
          expect(logger).to receive(:warn) do |message|
            expect(message).to include('broken')
          end
          expect{circuit.pass(:bar)}.to raise_error(BarError)
          expect(logger).not_to receive(:warn)
          expect{circuit.pass(:bar)}.to raise_error(BarError)
        end
      end

      context 'when the next call is successful again' do
        let(:foo) do
          Class.new do
            def initialize
              @messages = 0
            end

            def bar
              @messages += 1

              if @messages < 3
                fail BarError
              else
                :baz
              end
            end
          end.new
        end

        let(:circuit){ SimpleCircuit.new(payload: foo, max_failures: 1, retry_in: 1) }

        it 'closes back the circuit' do
          expect{circuit.pass(:bar)}.to raise_error(BarError)
          expect{circuit.pass(:bar)}.to raise_error(BarError)
          expect(circuit).to be_open
          expect{circuit.pass(:bar)}.to raise_error(BarError)
          sleep 1
          expect(circuit.pass(:bar)).to eq(:baz)
          expect(circuit).to be_closed
        end
      end

      context 'when payload raises different errors' do
        class Error1 < RuntimeError; end
        class Error2 < RuntimeError; end

        let(:foo) do
          Class.new do
            def initialize
              @errors = [Error1, Error2, Error1]
            end

            def bar
              fail @errors.shift
            end
          end.new
        end

        let(:circuit){ SimpleCircuit.new(payload: foo, max_failures: 1) }

        it 'fails with top error after break' do
          expect{circuit.pass(:bar)}.to raise_error(Error1)
          expect{circuit.pass(:bar)}.to raise_error(Error2)
          expect(circuit).to be_closed
          expect{circuit.pass(:bar)}.to raise_error(Error1)
          expect(circuit).to be_open
          expect{circuit.pass(:bar)}.to raise_error(Error1)
        end
      end
    end
  end
end
