require 'rspec'

require 'ai_player'
require 'card'

describe AIPlayer do
  let(:cards) do
    [ Card.new(:hearts, :five),
      Card.new(:diamonds, :four),
      Card.new(:hearts, :four) ]
  end

  describe "#initialize" do
    it "sets the players initial cards" do
      expect(AIPlayer.new(cards.dup).cards).to eq(cards)
    end
  end

  describe "::deal_player_in" do
    it "deals eight cards from the deck to a new player" do
      deck = double("deck")
      cards = double("cards")
      expect(deck).to receive(:take).with(8).and_return(cards)

      player = AIPlayer.deal_player_in(deck)
      expect(player.cards).to eq(cards)
    end
  end

  describe "#favorite suit" do
    it "computes the suit player has the most of" do
      expect(AIPlayer.new(cards).favorite_suit).to eq(:hearts)
    end
  end

  context "with single card" do
    subject(:player) { AIPlayer.new(cards) }
    let(:cards) { [card] }

    let(:pile) { double("pile") }

    context "with non-eight" do
      let(:card) { Card.new(:spades, :three) }

      describe "#play_card" do
        it "plays normally" do
          # **must call `play` on the Pile**
          expect(pile).to receive(:play).with(card)
          player.play_card(pile, card)
        end

        it "card must be in your hand to play it" do
          expect do
            # create a card outside your hand.
            other_card = Card.new(:spades, :ace)
            player.play_card(pile, other_card)
          end.to raise_error("cannot play card outside your hand")
        end

        it "removes card from hand" do
          # let the AIPlayer call `Pile#play`, but don't actually do
          # anything.
          pile.stub(:play)

          player.play_card(pile, card)
          expect(player.cards).to_not include(card)
        end
      end
    end

    context "with eight" do
      let(:card) { Card.new(:spades, :eight) }

      it "plays an eight by picking the favorite suit" do
        # **must use the `#favorite_suit` method in `#play_card`**.
        player.stub(:favorite_suit => :hearts)
        # **must call `play_eight` on the Pile**
        expect(pile).to receive(:play_eight).with(card, :hearts)

        player.play_card(pile, card)
      end
    end
  end

  describe "#draw_from" do
    subject(:player) { AIPlayer.new([]) }

    it "adds a card from the deck to hand" do
      card = Card.new(:clubs, :deuce)
      deck = double("deck")
      deck.stub(:take).with(1).and_return([card])

      player.draw_from(deck)
      expect(player.cards).to eq([card])
    end
  end

  describe "#choose_card" do
    subject(:player) { AIPlayer.new(cards) }

    let(:pile) { double("pile") }

    context "with a single card" do
      let(:cards) { [card] }
      let(:card) { Card.new(:clubs, :deuce) }

      it "choose a legal card if possible" do
        # **must call `valid_play?` in `choose_card`**
        pile.stub(:valid_play?).with(card).and_return(true)

        expect(player.choose_card(pile)).to eq(card)
      end

      it "returns nil if no legal play is possible" do
        pile.stub(:valid_play?).with(card).and_return(false)

        expect(player.choose_card(pile)).to be_nil
      end
    end

    context "with a choice between eight and non-eight" do
      let(:cards) { [eight, non_eight] }

      let(:eight) { Card.new(:diamonds, :eight) }
      let(:non_eight) { Card.new(:hearts, :three) }

      it "doesn't play eights ahead of any other option" do
        # either play is valid
        pile.stub(:valid_play?).and_return(true)

        cards.permutation.each do |cards|
          # no matter the order, must not play eight
          player = AIPlayer.new(cards)

          expect(player.choose_card(pile)).to eq(non_eight)
        end
      end

      it "plays an eight if there is no choice" do
        pile.stub(:valid_play?).and_return do |card|
          card == eight
        end

        expect(AIPlayer.new(cards).choose_card(pile)).to eq(eight)
      end
    end
  end
end
